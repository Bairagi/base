
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

%w{
  /opt/goatos/bin
  /opt/goatos/.config
  /opt/goatos/.config/lxc
  /opt/goatos/.local
  /opt/goatos/.local/share
  /opt/goatos/.local/share/lxc
  /opt/goatos/.local/share/lxcsnaps
  /opt/goatos/.cache
  /opt/goatos/.cache/lxc
  /opt/goatos/.ssh
  /opt/goatos/lxc.conf.d
  }.each do |dir|
  directory dir do
    user node['goatos']['user']
    group node['goatos']['group']
    mode 0750
  end
end

file '/etc/lxc/lxc-usernet' do
  owner 'root'
  group 'root'
  mode 0644
  content "#{node['goatos']['user']} veth lxcbr0 100\n"
end

cookbook_file '/opt/goatos/bin/goatos-meta' do
  source 'goat-meta.rb'
  mode 0700
  user node['goatos']['user']
  group node['goatos']['group']
end
