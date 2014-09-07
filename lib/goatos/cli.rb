require 'goatos/log'
require 'highline/import'
require 'goatos/builder'
require 'goatos/cli/lxc'
require 'thor'
require 'thor/group'

module GoatOS
  class CLI < Thor
    include Builder

    desc 'bootstrap -t HOSTNAME -u SSH_USER', 'Bootstrap a server'

    option :host,
      aliases: '-h',
      required: true,
      description: 'Host IP/FQDN'

    option :user,
      aliases: '-u',
      default: ENV['USER'],
      description: 'SSH user name'

    option :name,
      aliases: '-N',
      description: 'chef node name of the node (default sauron)',
      default: 'sauron'

    option :type,
      aliases: '-T',
      default: 'standalone',
      description: 'Type of bootstrap ("master" or "slave" or "standalone")'

    option :key,
      aliases: '-i',
      description: 'SSH identity key'

    option :password,
      aliases: '-P',
      description: 'Password for ssh user',
      type: :boolean

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

    register GoatOS::CLI::Lxc, :lxc, 'lxc', 'Manage LXC lifecycle'
  end
end
