require 'goatos/blends/helper'

module GoatOS
  module Blends
    class Slave
      def self.build(config_file)
        Blender.blend 'building slave', config_file do |sched|
          sched.config(:ruby, stdout: $stdout)
          sched.config(:ssh, stdout: $stdout)
          goatos = Blender::Configuration[:goatos]
          sched.members [goatos['target']]

          sched.ssh_task 'sudo apt-get update -y'

          sched.ruby_task 'bootstrap' do
            execute do |h|
              extend Helper
              knife Chef::Knife::Bootstrap, h do |config|
                config[:ssh_user] = Blender::Configuration[:ssh]['user']
                config[:ssh_password] = Blender::Configuration[:ssh]['password']
                config[:ssh_port] = 22
                config[:chef_node_name] = goatos['name']
                config[:distro] = 'chef-full'
                config[:use_sudo] = true
                config[:use_sudo_password] = true
              end
            end
          end

          sched.ruby_task 'set slave node intermediate run list' do
            execute do |h|
              extend Helper
              set_node goatos['name'], run_list: 'role[install]'
            end
          end

          sched.ssh_task 'run chef' do
            execute 'sudo chef-client --no-fork'
          end

          sched.ruby_task 'Store SSH key' do
            execute do |h|
              extend Helper
              File.open("keys/#{goatos['name']}.rsa", 'w') do |f|
                f.write(fetch_node(goatos['name'], attrs: 'goatos')['sshkey'])
                f.chmod(0600)
              end
            end
          end

          sched.ruby_task 'set slave nodes final run list' do
            execute do |h|
              extend Helper
              set_node goatos['name'], run_list: 'role[slave]'
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
