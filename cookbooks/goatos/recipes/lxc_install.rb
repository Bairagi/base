
%w{ liblxc1 lxc lxc-dev lxc-templates python3-lxc cgmanager-utils build-essential haproxy}.each do |pkg|
  package pkg do
    action :install
  end

end

%w{ruby-lxc serfx sshkey}.each do |gem_name|
  gem_package gem_name do
    gem_binary '/opt/chef/embedded/bin/gem'
  end
end

user 'goatos' do
  home '/opt/goatos'
  shell '/bin/bash'
  supports(manage_home: true)
end

directory '/opt/goatos/.config' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0700
end

directory '/opt/goatos/.config/lxc' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0775
end

directory '/opt/goatos/.local' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0751
end

directory '/opt/goatos/.local/share' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0751
end

directory '/opt/goatos/.local/share/lxc' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0751
end

directory '/opt/goatos/.local/share/lxcsnaps' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0751
end

directory '/opt/goatos/.cache' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0751
end

directory '/opt/goatos/.cache/lxc' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0751
end

directory '/opt/goatos/.ssh' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0700
end

directory '/opt/goatos/lxc.conf.d' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0751
end

file '/etc/lxc/lxc-usernet' do
  owner 'root'
  group 'root'
  mode 0644
  content "#{node['goatos']['user']} veth lxcbr0 100\n"
end
