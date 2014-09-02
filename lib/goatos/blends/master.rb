require 'goatos/blends/helper'

module GoatOS
  module Blends
    class Master
      def self.build
        Blender.blend 'building master' do |sched|
          sched.config(:ssh, stdout: $stdout)
          sched.members [ Blender::Configuration[:goatos]['target']]

          sched.ssh_task 'sudo apt-get update -y'

          sched.ssh_task 'download chef server' do
            execute 'wget -c https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.1.4-1_amd64.deb'
          end

          sched.ssh_task 'install chef server' do
            execute 'sudo dpkg -i chef-server_11.1.4-1_amd64.deb'
          end

          sched.ssh_task 'reconfigure chef server' do
            execute 'sudo chef-server-ctl reconfigure'
          end

          %w(admin.pem chef-validator.pem).each do |key|
            printer = StringIO.new
            sched.ssh_task "retrieve  file '#{key}'" do
              execute "sudo cat /etc/chef-server/#{key}"
              driver_options(stdout: printer )
            end

            sched.ruby_task "store file '#{key}'" do
              execute do |h|
                File.open(File.join('keys', key), File::CREAT|File::RDWR|File::EXCL) do |f|
                  f.write(printer.string.gsub(/^blender sudo password:\s*$/,'').strip)
                end
                printer.rewind
              end
            end
          end

          sched.ruby_task 'wait 10s' do
            execute do
              sleep 10
            end
          end

          sched.ruby_task 'save knife config' do
            execute do |h|
              File.open('etc/knife.rb', File::CREAT|File::RDWR|File::EXCL) do |f|
                f.puts <<-EOF
                  cwd = File.expand_path('../../', __FILE__)
                  chef_server_url 'https://#{h}'
                  node_name 'admin'
                  client_key File.join(cwd, 'keys/admin.pem')
                  validation_key File.join(cwd, 'keys/chef-validator.pem')
                EOF
              end
            end
          end

          sched.ruby_task 'upload cookbooks' do
            execute do |h|
              extend GoatOS::Helper
              knife Chef::Knife::RoleFromFile, 'roles/slave.rb', 'roles/install.rb'
              knife Chef::Knife::CookbookUpload do |config|
                config[:cookbook_path] = 'cookbooks'
                config[:all] = true
              end
            end
            driver_options(stdout: $stdout)
          end
        end
      end
    end
  end
end
