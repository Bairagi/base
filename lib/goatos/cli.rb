require 'goatos/log'
require 'highline/import'
require 'goatos/builder'
require 'goatos/cli/lxc'
require 'thor'
require 'thor/group'

module GoatOS
  class CLI < Thor
    include Builder

    register GoatOS::CLI::Lxc, :lxc, 'lxc', 'Manage LXC lifecycle'

    desc 'bootstrap -t HOSTNAME -u SSH_USER', 'Bootstrap a server'

    option :host,
      aliases: '-h',
      required: true,
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

    def bootstrap(cwd = Dir.pwd)
      opts = options.dup
      if options[:password]
        password = ask('SSH Password: '){ |q| q.echo = false }
        opts.merge!(password: password)
      end
      Dir.chdir(cwd) do
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
    end
  end
end
