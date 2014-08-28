require 'goatos_helper'
config(:ssh, stdout: $stdout)
members [ Blender::Configuration[:goatos]['target']]

ssh_task 'sudo apt-get update -y'

ssh_task 'download chef server' do
  execute 'wget -c https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.1.4-1_amd64.deb'
end

ssh_task 'install chef server' do
  execute 'sudo dpkg -i chef-server_11.1.4-1_amd64.deb'
end

ssh_task 'reconfigure chef server' do
  execute 'sudo chef-server-ctl reconfigure'
end

%w(admin.pem chef-validator.pem).each do |key|
  printer = StringIO.new
  ssh_task "retrieve  file '#{key}'" do
    execute "sudo cat /etc/chef-server/#{key}"
    driver_options(stdout: printer )
  end

  ruby_task "store file '#{key}'" do
    execute do |h|
      File.open(File.join('keys', key), 'w') do |f|
        f.write(printer.string.gsub(/^blender sudo password:\s*$/,'').strip)
      end
      printer.rewind
    end
  end
end

ruby_task 'wait 10s' do
  execute do
    sleep 10
  end
end

ruby_task 'upload cookbooks' do
  execute do
    extend GoatOS::Helper
    knife Chef::Knife::RoleFromFile, 'roles/slave.rb', 'roles/install.rb'
    knife Chef::Knife::CookbookUpload do |config|
      config[:cookbook_path] = 'cookbooks'
      config[:all] = true
    end
  end
  driver_options(stdout: $stdout)
end

ruby_task 'save knife config' do
  execute do |h|
    File.open('etc/knife.rb', 'w') do |f|
      f.puts("chef_server_url 'https://#{h}'")
      f.puts("node_name 'admin'")
      f.puts("client_key '../keys/admin.pem'")
      f.puts("validation_key '../keys/chef-validator.pem'")
    end
  end
end
