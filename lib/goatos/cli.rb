require 'goatos/log'
require 'highline/import'
require 'goatos/builder'
require 'goatos/cli/lxc'
require 'thor'
require 'thor/group'

module GoatOS
  class CLI < Thor
    include Builder

    def self.exit_on_failure?
      true
    end

    register GoatOS::CLI::Lxc, :lxc, 'lxc', 'Manage LXC lifecycle'

    desc 'bootstrap -t HOSTNAME -u SSH_USER', 'Bootstrap a server'

    option :host,
      aliases: '-h',
      description: 'Host IP/FQDN'

    option :name,
      aliases: '-N',
      description: 'chef node name of the node (default sauron)',
      default: 'sauron'

    option :type,
      aliases: '-T',
      default: 'standalone',
      description: 'Type of bootstrap ("master", "slave" or "standalone")'

    option :user,
      aliases: '-u',
      default: ENV['USER'],
      description: 'SSH user name'

    option :key,
      aliases: '-i',
      description: 'SSH identity key'

    option :password,
      aliases: '-P',
      description: 'Password for ssh user',
      type: :boolean

    option :ssh_port,
      aliases: '-p',
      description: 'SSH Port',
      type: :string,
      default: '22'

    option :environment,
      aliases: '-E',
      description: 'Chef environment',
      type: :string,
      default: '_default'

    option :run_list,
      aliases: '-r',
      description: 'Chef run list',
      type: :string

    option :cloud,
      description: 'Use a provisioner to spawn instance',
      type: :string
    def bootstrap(cwd = Dir.pwd)
      opts = options.dup
      if options[:password]
        password = ask('SSH Password: '){ |q| q.echo = false }
        opts.merge!(password: password)
      end
      Dir.chdir(cwd) do
        if options[:cloud]
          details = create_machine( opts[:name], opts[:cloud], opts[:ssh_port] )
          opts[:host] = details[:host]
        elsif opts[:host].nil?
          abort 'You must supply host IP/fqdn  if cloud is not provided'
        end
        case options[:type]
        when 'master'
          build_master( opts )
        when 'slave'
          build_slave( opts )
        when 'standalone'
          build_standalone( opts )
        else
          abort 'only master, slave or standalone bootstrap is valid'
        end
      end
    end

    desc 'run-chef', 'Run chef across fleet'

    option :user,
      aliases: '-u',
      default: ENV['USER'],
      description: 'SSH user name'

    option :key,
      aliases: '-i',
      description: 'SSH identity key'

    option :password,
      aliases: '-P',
      description: 'Password for ssh user',
      type: :boolean

    option :filter,
      aliases: '-f',
      default: '*:*',
      description: 'Search term to predicate host list'

    option :attribute,
      aliases: '-a',
      default: 'ipaddress',
      description: 'Node attribute to be used for ssh hostname'

    option :run_list,
      aliases: '-r',
      description: 'Node attribute to be used for ssh hostname'

    def run_chef
      ssh_opts = { user: options[:user] }
      if options[:password]
        password = ask('SSH Password: '){ |q| q.echo = false }
        ssh_opts[:password] = password
      else
        ssh_opts[:keys] = [ options[:key] ]
      end

      chef_opts= {
        attribute: options[:attribute],
        filter: options[:filter],
      }
      if options[:run_list]
        chef_command = "sudo /opt/chef/bin/chef-client --no-fork -o #{options[:run_list]}"
      else
        chef_command = 'sudo /opt/chef/bin/chef-client --no-fork'
      end

      run_blender(
        chef_command,
        ssh_opts,
        chef_opts
      )
    end

    desc 'meta', 'Show lxc related metadata'
    def meta
      ssh_opts = {
        keys: [ 'keys/goatos.rsa' ],
        user: 'goatos'
      }

      chef_opts= {
        attribute: options[:attribute],
        filter: options[:filter],
      }
      if options[:show]
        meta_command = '/opt/goatos/bin/goat-meta show'
      elsif options[]
        raise ArgumentError, 'Meta command not implemented'
      end
      run_blender(
        meta_command,
        ssh_opts,
        chef_opts
      )
    end

    desc 'init', 'Create GoatOS directory structure'
    def init(cwd = Dir.pwd)
      Dir.chdir(cwd) do
        %w{cookbooks keys roles environments etc}.each do |dir|
          unless File.exist?(dir)
            Dir.mkdir(dir)
          end
        end
        Dir["#{File.expand_path('../../../roles', __FILE__)}/*.rb"].each do |f|
          FileUtils.cp( f, "roles/#{File.basename(f)}")
        end
        Dir["#{File.expand_path('../../../cookbooks', __FILE__)}/*"].each do |f|
          FileUtils.cp_r( f, "cookbooks/#{File.basename(f)}")
        end
      end
    end

    no_commands do

      def run_blender(command, ssh_opts, chef_opts)
        Blender.blend('goatos_run_chef') do |sched|
          sched.config(:chef, config_file: 'etc/knife.rb', attribute: chef_opts[:attribute])
          sched.config(:ruby, stdout: $stdout)
          sched.config(:ssh, ssh_opts.merge(stdout: $stdout))
          sched.members(sched.search(:chef, chef_opts[:filter]))
          sched.ssh_task command
        end
      end

      # create_machine(name, options[:cloud], ssh_port)
      def create_machine(name, config_file, ssh_port)
        require 'goatos/cloud'
        require 'goatos/cloud/providers/digital_ocean'
        config = YAML.load(File.read( config_file ))
        klass = GoatOS::Cloud.provider(config['provider'])
        provisioner = klass.new(config['credentials'])
        machine_options = config['machine_options']
        details = provisioner.create(options[:name], machine_options)
        puts "Waiting till host becomes reachable"
        until host_reachable?(details[:host], ssh_port )
          sleep 10
          print '.'
        end
        details
      end

      def host_reachable?(host, port)
        socket = TCPSocket.new(host, port)
        if IO.select([socket], nil, nil, 5)
          banner = socket.gets
          banner and !banner.empty?
        else
          false
        end
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError, Errno::EPERM, Errno::ETIMEDOUT, Errno::ECONNRESET
        false
      ensure
        socket && socket.close
      end
    end
  end
end
