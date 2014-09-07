require 'thor'
require 'blender/chef'

module GoatOS
  class CLI < Thor
    class Lxc < Thor
      class_option :filter,
        aliases: '-f',
        default: '*:*',
        description: 'Search term to predicate host list'
      class_option :attribute,
        aliases: '-a',
        default: 'ipaddress',
        description: 'Node attribute to be used for ssh hostname'

      desc 'lxc ls', 'list all lxc'
      def ls
        opts = options.dup
        run_blender('lxc-ls --fancy', opts)
      end

      desc 'lxc create', 'create a container'
      option :template,
        default: 'download',
        aliases: '-t',
        description: 'Template for building rootfs'
      option :arch,
        default: 'amd64',
        aliases: '-a',
        description: 'ARCH for the lxc'
      option :distro,
        default: 'ubuntu',
        aliases: '-d',
        description: 'Disro type to be used with download template'
      option :release,
        default: 'trusty',
        aliases: '-r',
        description: 'Release of a distribution (e.g lucid, precise, trusty for ubuntu)'
      option :name,
        required: true,
        aliases: '-N',
        description: 'Name of the container'
      def create
        opts = options.dup
        command =[ 'lxc-create']
        command += ['-t', opts[:template]]
        command += ['-n', opts[:name], '--']
        command += ['-d', opts[:distro]]
        command += ['-r', opts[:release]]
        command += ['-a', opts[:arch]]

        run_blender(command.join(' '), opts)
      end
      no_commands do
        def run_blender(command, opts)
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
