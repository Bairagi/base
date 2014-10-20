require 'goatos/log'
require 'highline/import'
require 'goatos/cli/lxc'
require 'goatos/runner'
require 'thor'
require 'thor/group'

module GoatOS
  class CLI < Thor

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
      runner = GoatOS::Runner.new(
        repo_dir: Dir.pwd,
        conf_dir: File.join(Dir.pwd, 'etc')
      )
      if options[:cloud]
        details = runner.create_machine( opts[:name], opts[:cloud], opts[:ssh_port] )
        opts[:host] = details[:host]
      elsif opts[:host].nil?
        abort 'You must supply host IP/fqdn  if cloud is not provided'
      end
      runner.provision(opts)
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
      chef_opts= { attribute: options[:attribute], filter: options[:filter] }
      if options[:run_list]
        chef_command = "sudo /opt/chef/bin/chef-client --no-fork -o #{options[:run_list]}"
      else
        chef_command = 'sudo /opt/chef/bin/chef-client --no-fork'
      end
      runner = GoatOS::Runner.new(
        repo_dir: Dir.pwd,
        conf_dir: File.join(Dir.pwd, 'etc')
      )
      runner.run_blender( chef_command, ssh_opts, chef_opts )
    end

    desc 'meta', 'Show lxc related metadata'
    def meta
      ssh_opts = { keys: [ 'keys/goatos.rsa' ], user: 'goatos' }
      chef_opts= { attribute: options[:attribute], filter: options[:filter] }
      if options[:show]
        meta_command = '/opt/goatos/bin/goat-meta show'
      elsif options[]
        raise ArgumentError, 'Meta command not implemented'
      end
      runner = GoatOS::Runner.new(repo_dir: Dir.pwd)
      runner.run_blender( meta_command, ssh_opts, chef_opts )
    end

    desc 'init', 'Create GoatOS directory structure'
    def init
      runner = GoatOS::Runner.new(repo_dir: Dir.pwd)
      runner.create_repo
    end
  end
end
