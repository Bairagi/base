require 'goatos/blends/helper'

module GoatOS
  module Blends
    module Bootstrapper

      def add_bootstrap_tasks(sched, node_name, options)
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
      end

      def add_chef_run_task(sched, node_name, run_list)
        sched.ruby_task 'run chef' do
          execute do |h|
            extend Helper
            chef_node(node_name) do |node|
              node.run_list.reset!
              node.run_list << run_list
              node.save
            end
          end
        end
        sched.ssh_task 'run chef' do
          execute 'sudo chef-client --no-fork'
        end
      end
    end
  end
end
