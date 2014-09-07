require 'goatos/blends/master'
require 'goatos/blends/slave'
require 'goatos/blends/helper'
require 'chef/knife/bootstrap'
require 'chef/knife/cookbook_upload'
require 'chef/knife/role_from_file'
require 'goatos/log'

module GoatOS
  module Builder
    def build_master( options )
      Blends::Master.build( options )
    end
    def build_slave( options )
      Blends::Slave.build( options )
    end

    def build_standalone( options )
      Blends::Master.build( options )
      Blends::Slave.build( options )

      Blender.blend( 'building master') do |sched|
        sched.config(:ssh, stdout: $stdout, user: options[:user], password: options[:password])
        sched.members [ options[:host]]
        sched.ruby_task 'set master run list' do
          execute do |h|
            extend Blends::Helper
            set_node options[:name], run_list: 'role[standalone]'
          end
        end

        sched.ssh_task 'run chef' do
          execute 'sudo chef-client --no-fork'
        end
      end
    end
  end
end
