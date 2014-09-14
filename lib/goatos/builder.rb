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

    def build_master( options )
      ssh_options = ssh_opts(options)
      host = options[:host]
      node_name = options[:name]
      Blender.blend( 'build_master') do |sched|
        sched.config(:ssh, ssh_options.merge(stdout: $stdout))
        sched.members([ host])
        add_master_tasks( sched, node_name, options )
        add_bootstrap_tasks( sched, node_name, options )
        add_sshkey_task(sched, node_name)
        add_chef_run_task(sched, node_name, 'role[master]')
      end
    end

    def build_lxc( options )
      ssh_options = ssh_opts(options)
      host = options[:host]
      node_name = options[:name]
      Blender.blend( 'build_lxc') do |sched|
        sched.config(:ssh, ssh_options.merge(stdout: $stdout))
        sched.config(:ruby, stdout: $stdout)
        sched.members([ host])
        sched.ssh_task 'sudo apt-get update  -y'
        sched.ssh_task 'sudo apt-get install wget curl libwww-perl  -y'
        add_bootstrap_tasks( sched, node_name, options )
      end
    end

    def build_slave( options )
      ssh_options = ssh_opts(options)
      host = options[:host]
      node_name = options[:name]
      Blender.blend( 'build_slave') do |sched|
        sched.config(:ssh, ssh_options.merge(stdout: $stdout))
        sched.members([ host])
        add_bootstrap_tasks( sched, node_name, options )
        add_slave_tasks( sched, options )
        add_chef_run_task(sched, node_name, 'role[slave]')
      end
    end

    def build_standalone( options )
      ssh_options = ssh_opts(options)
      host = options[:host]
      node_name = options[:name]
      Blender.blend( 'build_standalone') do |sched|
        sched.config(:ssh, ssh_options.merge(stdout: $stdout))
        sched.members([ host])
        add_master_tasks( sched, node_name, options)
        add_bootstrap_tasks( sched, node_name, options )
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

    def ssh_opts(options)
      ssh_options = {user: options[:user], port: options[:ssh_port]}
      if options[:password]
        ssh_options[:password] = options[:password]
      elsif options[:key]
        ssh_options[:keys] = Array( options[:key] )
      end
      ssh_options
    end
  end
end
