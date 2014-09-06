file '/opt/goatos/admin.pem' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0400
  content ::File.read('/etc/chef-server/admin.pem')
end

remote_file '/opt/goatos/chef-validator.pem' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0400
  source 'file:///etc/chef-server/chef-validator.pem'
end
