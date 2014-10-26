require 'goatos/blends/master'
require 'goatos/blends/slave'
require 'goatos/blends/helper'
require 'chef/knife/bootstrap'
require 'chef/knife/cookbook_upload'
require 'chef/knife/role_from_file'
require 'goatos/log'
require 'goatos/blends/bootstrap'

module GoatOS
  module Builder
    include Blends::Master
    include Blends::Slave
    include Blends::Bootstrapper

    def common_build(name, options)
      ssh_options = {user: options[:user], port: options[:ssh_port]}
      if options[:password]
        ssh_options[:password] = options[:password]
      elsif options[:key]
        ssh_options[:keys] = Array( options[:key] )
      end
      host = options[:host]
      Blender.blend(name) do |sched|
        sched.config(:ssh, ssh_options.merge(stdout: $stdout))
        sched.config(:ruby, stdout: $stdout)
        sched.members([ host])
        yield sched if block_given?
      end
    end

    def build_master( options )
      node_name = options[:name]
      common_build('build_master', options) do |sched|
        add_master_tasks( sched, node_name, options )
        add_blender_bootstrap_tasks( sched, node_name, options )
        add_sshkey_task(sched, node_name)
        add_chef_run_task(sched, node_name, 'role[master]')
      end
    end

    def build_slave( options )
      node_name = options[:name]
      common_build('build_slave', options) do |sched|
        add_blender_bootstrap_tasks( sched, node_name, options )
        add_slave_tasks( sched, options )
        add_chef_run_task(sched, node_name, 'role[slave]')
      end
    end

    def build_standalone( options )
      node_name = options[:name]
      common_build( 'build_standalone', options) do |sched|
        add_master_tasks( sched, node_name, options )
        add_blender_bootstrap_tasks( sched, node_name, options )
        add_chef_run_task(sched, node_name, 'role[master]')
        add_sshkey_task(sched, node_name)
        sched.ruby_task 'avoid stale chef search' do
          execute do |h|
            sleep 10
          end
        end
        add_slave_tasks( sched, options )
        add_chef_run_task(sched, node_name, 'role[standalone]')
      end
    end
  end
end
