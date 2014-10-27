package 'git'

gem_package 'librarian-chef' do
  gem_binary '/opt/chef/embedded/bin/gem'
end

directory  "#{node['goatos']['home_dir']}/builder" do
  owner node['goatos']['user']
  group node['goatos']['group']
  mode 0775
end

cookbook_file "#{node['goatos']['home_dir']}/builder/Cheffile" do
  owner node['goatos']['user']
  group node['goatos']['group']
  mode 0644
  source 'cheffile.rb'
end

template "#{node['goatos']['home_dir']}/builder/knife.rb" do
  owner node['goatos']['user']
  group node['goatos']['group']
  mode 0644
  variables(ip: node['goatos']['goiardi_ip'])
  source 'knife.rb.erb'
end

remote_file "#{node['goatos']['home_dir']}/builder/admin.pem" do
  owner node['goatos']['user']
  group node['goatos']['group']
  mode 0400
  source 'file:///etc/goiardi/admin.pem'
end

remote_file "#{node['goatos']['home_dir']}/builder/validation.pem" do
  owner node['goatos']['user']
  group node['goatos']['group']
  mode 0400
  source 'file:///etc/goiardi/chef-validator.pem'
end
