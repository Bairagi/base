require 'goatos/log'
require 'highline/import'

module GoatOS
  class CLI

    include Mixlib::CLI
    include Builder

    option :target,
      short: '-t TARGET',
      long: '--target TARGET',
      required: true,
      description: 'Target host IP/FQDN'


    option :user,
      short: '-u USER',
      long: '--user USER',
      required: true,
      description: 'SSH user name'

    option :name,
      short: '-N NAME',
      long: '--name NAME',
      description: 'chef node name of the node (default sauron)',
      default: 'sauron'

    option :bootstrap,
      short: '-b master',
      long: '--bootstrap master',
      default: 'standalone',
      description: 'Bootstrap a node  (can be "master" or "slave" or "standalone")'


    def bootstrap(cwd = Dir.pwd)
      Dir.chdir(cwd) do
        write_config
        Blender.blend('GoatOS_Bootstrap') do |sched|
          build = Builder.new(sched)

          sched.config(:shell_out, stdout: $stdout, timeout: 3600)
          sched.members ['localhost']
          case config[:bootstrap]
          when 'master'
            build.master
          when 'slave'
            build.master
          when 'standalone'
            build.standalone
          else
            abort 'only master, slave or standalone bootstrap is valid'
          end
        end
      end
    end

    def write_config( path = 'config.json' )
      password = ask('SSH Password: '){ |q| q.echo = false }
      sub_config = {
        scheduler:{
          ssh: { user: config[:user], password: password },
          goatos: { target: config[:target], name: config[:name]}
        }
      }
      File.open(path, 'w') do |f|
        f.write(JSON.pretty_generate(sub_config))
      end
    end
  end
end
