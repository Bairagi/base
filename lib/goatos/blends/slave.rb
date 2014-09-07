require 'goatos/blends/helper'

module GoatOS
  module Blends
    class Slave
      def self.build( options )
        host = options[:host]
        node_name = options[:name]
        ssh_options = {user: options[:user]}
        if options[:password]
          ssh_options[:password] = options[:password]
        elsif options[:key]
          ssh_options[:keys] = Array( options[:key] )
        end
        Blender.blend 'building slave' do |sched|
          sched.config(:ruby, stdout: $stdout)
          sched.config(:ssh, ssh_options.merge(stdout: $stdout))
          sched.members [ host ]

          sched.ssh_task 'sudo apt-get update -y'

          sched.ruby_task 'bootstrap' do
            execute do |h|
              extend Helper
              knife Chef::Knife::Bootstrap, h do |config|
                config[:ssh_user] = options[:user]
                if options[:password]
                  config[:ssh_password] = options[:password]
                  config[:use_sudo_password] = true
                elsif options[:key]
                  config[:identity_file] = options[:key]
                end
                config[:ssh_port] = 22
                config[:chef_node_name] = node_name
                config[:distro] = 'chef-full'
                config[:use_sudo] = true
              end
            end
          end

          sched.ruby_task 'set slave node intermediate run list' do
            execute do |h|
              extend Helper
              set_chef_node_run_list(node_name, 'recipe[goatos::install]')
            end
          end

          sched.ssh_task 'run chef' do
            execute 'sudo chef-client --no-fork'
          end

          sched.ruby_task 'set slave nodes final run list' do
            execute do |h|
              extend Helper
              set_chef_node_run_list( node_name, 'role[slave]')
            end
          end

          sched.ssh_task 'run chef' do
            execute 'sudo chef-client --no-fork'
          end
        end
      end
    end
  end
end
