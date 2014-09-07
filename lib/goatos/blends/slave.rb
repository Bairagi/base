require 'goatos/blends/helper'

module GoatOS
  module Blends
    class Slave
      def self.build( options )
        Blender.blend 'building slave' do |sched|
          sched.config(:ruby, stdout: $stdout)
          sched.config(:ssh, stdout: $stdout, user: options[:user], password: options[:password])
          sched.members [ options[:host] ]

          sched.ssh_task 'sudo apt-get update -y'

          sched.ruby_task 'bootstrap' do
            execute do |h|
              extend Helper
              knife Chef::Knife::Bootstrap, h do |config|
                config[:ssh_user] = options[:user]
                config[:ssh_password] = options[:password]
                config[:ssh_port] = 22
                config[:chef_node_name] = options[:name]
                config[:distro] = 'chef-full'
                config[:use_sudo] = true
                config[:use_sudo_password] = true
              end
            end
          end

          sched.ruby_task 'set slave node intermediate run list' do
            execute do |h|
              extend Helper
              set_node options[:name], run_list: 'role[install]'
            end
          end

          sched.ssh_task 'run chef' do
            execute 'sudo chef-client --no-fork'
          end

          sched.ruby_task 'set slave nodes final run list' do
            execute do |h|
              extend Helper
              set_node options[:name], run_list: 'role[slave]'
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
