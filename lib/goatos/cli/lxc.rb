require 'thor'
require 'blender/chef'

module GoatOS
  class CLI < Thor
    class Lxc < Thor

      desc 'lxc ls', 'list all lxc'
      option :filter,
        aliases: '-f',
        default: '*:*',
        description: 'Search term to predicate host list'
      option :attribute,
        aliases: '-a',
        default: 'ipaddress',
        description: 'Node attribute to be used for ssh hostname'

      def ls
        opts = options.dup
        run_blender('lxc-ls --fancy', opts)
      end
      no_commands do
        def run_blender(command, opts)
          puts opts.inspect
          Blender.blend('goatos_lxc') do |sched|
            sched.config(:chef, config_file: 'etc/knife.rb', attribute: opts[:attribute])
            sched.config(:ruby, stdout: $stdout)
            sched.config(:ssh, stdout: $stdout, user: 'goatos', keys: ['keys/goatos.rsa'])
            sched.members(sched.search(:chef, opts[:filter]))
            sched.ssh_task command
          end
        end
      end
    end
  end
end
