require 'goatos/blends/helper'
require 'chef/knife/bootstrap'
require 'chef/knife/cookbook_upload'
require 'chef/knife/role_from_file'
require 'sshkey'
require 'tempfile'

module GoatOS
  module Blends
    module Bootstrapper

      def add_blender_bootstrap_tasks(sched, node_name, options)
        GoatOS::Blends::Helper.configure
        sched.ssh_task 'wget -c https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/13.04/x86_64/chef_11.16.4-1_amd64.deb'
        sched.ssh_task 'sudo dpkg -i chef_11.16.4-1_amd64.deb'
        sched.ssh_task 'sudo mkdir /etc/chef' do
          ignore_failure true
        end
        sched.ruby_task 'copy_validation_cert' do
          execute do |h|
            opts = {}
            if options[:password]
              opts[:password] = options[:password]
            elsif options[:key]
              opts[:keys] = Array( options[:key] )
            end
            Net::SCP.upload!(
              options[:host],
              options[:user],
              'keys/chef-validator.pem',
              '/tmp/chef-validator.pem',
              ssh: opts
            )
            file = Tempfile.new('client.rb')
            file.write("node_name \"#{node_name}\"\n")
            file.write("chef_server_url \"#{Chef::Config[:chef_server_url]}\"\n")
            file.close
            Net::SCP.upload!(
              options[:host],
              options[:user],
              file.path,
              '/tmp/client.rb',
              ssh: opts
            )
            file.unlink
          end
        end
        sched.ssh_task 'sudo mv /tmp/chef-validator.pem /etc/chef/validation.pem'
        sched.ssh_task 'sudo mv /tmp/client.rb /etc/chef/'
        sched.ssh_task 'sudo /opt/chef/embedded/bin/gem install chef -v 12.0.0.alpha.2 --no-ri --no-rdoc'
        sched.ssh_task 'sudo chef-client --no-fork'
      end

      def add_bootstrap_tasks(sched, node_name, options)
        sched.ruby_task "bootstrap #{node_name}" do
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
              config[:ssh_port] = options[:ssh_port].to_i
              config[:chef_node_name] = node_name
              config[:distro] = 'chef-full'
              config[:use_sudo] = true
            end
          end
        end
      end

      def add_sshkey_task(sched, node_name)
        sched.ruby_task 'assign ssh key' do
          execute do  |h|
            extend Helper
            key = SSHKey.generate
            File.open('keys/goatos.rsa', 'w') do |f|
              f.write(key.private_key)
              f.chmod(0600)
            end
            chef_node(node_name) do |node|
              node.set['goatos']['sshkey'] = key.ssh_public_key
              node.save
            end
          end
        end
      end

      def add_chef_run_task(sched, node_name, run_list)
        sched.ruby_task "set '#{node_name}' run list to '#{run_list}'" do
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
