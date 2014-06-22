
deb_path = ::File.join(Chef::Config[:file_cache_path], 'chef-server.deb')

remote_file deb_path do
  source 'https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/12.04/x86_64/chef-server_11.1.1-1_amd64.deb'
end

dpkg_package 'chef-server' do
  source deb_path
  notifies :run, 'execute[chef_server_reconfigure]', :immediately
  notifies :run 'ruby_block[copy_over_adminpem]'
end

execute 'chef_server_reconfigure' do
  command 'chef-server-ctl reconfigure'
  action :nothing
end
