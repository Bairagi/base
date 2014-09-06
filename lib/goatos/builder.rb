require 'goatos/blends/master'
require 'goatos/blends/slave'
require 'goatos/blends/helper'
require 'chef/knife/bootstrap'
require 'chef/knife/cookbook_upload'
require 'chef/knife/role_from_file'
require 'goatos/log'

module GoatOS
  module Builder
    def write_blender_config(path)
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
    def build_master( path = 'config.json' )
      write_blender_config(path)
      Blends::Master.build(path)
    end
    def build_slave( path = 'config.json' )
      write_blender_config(path)
      Blends::Slave.build(path)
    end

    def build_standalone( path = 'config.json' )
      write_blender_config(path)
      Blends::Master.build(path)
      Blends::Slave.build(path)

      Blender.blend( 'building master', path) do |sched|
        goatos = Blender::Configuration[:goatos]
        sched.config(:ssh, stdout: $stdout)
        sched.members [ Blender::Configuration[:goatos]['target']]
        sched.ruby_task 'set master run list' do
          execute do |h|
            extend Blends::Helper
            set_node goatos['name'], run_list: 'role[standalone]'
          end
        end

        sched.ssh_task 'run chef' do
          execute 'sudo chef-client --no-fork'
        end
      end
    end
  end
end
