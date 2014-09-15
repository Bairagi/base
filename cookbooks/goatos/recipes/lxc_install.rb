
%w{ liblxc1 lxc lxc-dev lxc-templates python3-lxc cgmanager-utils build-essential}.each do |pkg|
  package pkg do
    action :install
  end

end

%w{ruby-lxc serfx sshkey thor chef-lxc}.each do |gem_name|
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
  /opt/goatos/.local
  /opt/goatos/.local/share
  /opt/goatos/.cache
  /opt/goatos/.ssh
  /opt/goatos/lxc.conf.d
  /opt/goatos/recipes
  /opt/goatos/.config/lxc
  /opt/goatos/.local/share/lxc
  /opt/goatos/.local/share/lxcsnaps
  /opt/goatos/.cache/lxc
  }.each do |dir|
  directory dir do
    user node['goatos']['user']
    group node['goatos']['group']
    mode 0775
  end
end

file '/etc/lxc/lxc-usernet' do
  owner 'root'
  group 'root'
  mode 0644
  content "#{node['goatos']['user']} veth lxcbr0 100\n"
end

cookbook_file '/opt/goatos/bin/goatos-meta' do
  source 'goatos-meta.rb'
  mode 0700
  user node['goatos']['user']
  group node['goatos']['group']
end

cookbook_file '/opt/goatos/recipes/test.rb' do
  source 'test.rb'
  mode 0644
  user node['goatos']['user']
  group node['goatos']['group']
end
