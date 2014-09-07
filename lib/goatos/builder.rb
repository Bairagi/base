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
      host = options[:host]
      node_name = options[:name]
      ssh_options = {user: options[:user]}
      if options[:password]
        ssh_options[:password] = options[:password]
      elsif options[:key]
        ssh_options[:keys] = Array( options[:key] )
      end

      Blender.blend( 'building standalone') do |sched|
        sched.config(:ssh, ssh_options.merge(stdout: $stdout))
        sched.members([ host])
        sched.ruby_task 'set master run list' do
          execute do |h|
            extend Blends::Helper
            set_chef_node_run_list(node_name, 'role[standalone]')
          end
        end

        sched.ssh_task 'run chef' do
          execute 'sudo chef-client --no-fork'
        end
      end
    end
  end
end
