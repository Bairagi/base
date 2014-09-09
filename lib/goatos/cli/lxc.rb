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

      desc 'lxc start', 'start a container'
      option :name,
        aliases: '-N',
        required: true,
        description: 'Name of the container to start'
      def start
        opts = options.dup
        command = [ 'lxc-start', '-d' ]
        command += ['-n', opts[:name]]
        run_blender(command.join(' '), opts)
      end

      desc 'lxc stop', 'stop a container'
      option :name,
        aliases: '-N',
        required: true,
        description: 'Name of the container to stop'
      def stop
        opts = options.dup
        command = [ 'lxc-stop' ]
        command += ['-n', opts[:name]]
        run_blender(command.join(' '), opts)
      end

      desc 'lxc destroy', 'destroy a container'
      option :name,
        aliases: '-N',
        required: true,
        description: 'Name of the container to destroy'
      option :force,
        aliases: '-f',
        type: :boolean,
        description: 'Force destroy (will shutdown a container if its running)'
      def destroy
        opts = options.dup
        command = [ 'lxc-destroy' ]
        command += ['-n', opts[:name]]
        command << '-f' if opts[:force]
        run_blender(command.join(' '), opts)
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

      option :expose,
        description: 'Network service this container will expose ct_port:protocol:host_port'

      def create
        opts = options.dup
        command =[ 'lxc-create']
        command += ['-t', opts[:template]]
        command += ['-n', opts[:name], '--']
        command += ['-d', opts[:distro]]
        command += ['-r', opts[:release]]
        command += ['-a', opts[:arch]]
        commands = [ command.join(' ') ]
        if options[:expose]
          cmd = "/opt/goatos/bin/goatos-meta expose"
          cmd << " #{options[:name]} #{options[:expose]}"
          commands << cmd
        end
        run_blender( commands, opts)
      end

      desc 'meta', 'Show lxc related metadata'
      def meta
        command = '/opt/goatos/bin/goat-meta show'
        run_blender(
          command,
          options
        )
      end

      no_commands do
        def run_blender(commands, opts)
          Blender.blend('goatos_lxc') do |sched|
            sched.config(:chef, config_file: 'etc/knife.rb', attribute: opts[:attribute])
            sched.config(:ruby, stdout: $stdout)
            sched.config(:ssh, stdout: $stdout, user: 'goatos', keys: ['keys/goatos.rsa'])
            sched.members(sched.search(:chef, opts[:filter]))
            Array(commands).each do |cmd|
              sched.ssh_task cmd
            end
          end
        end
      end
    end
  end
end
