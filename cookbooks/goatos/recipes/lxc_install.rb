
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

user node['goatos']['user'] do
  home node['goatos']['home_dir']
  shell '/bin/bash'
  supports(manage_home: true)
end

%W{
  #{node['goatos']['home_dir']}/bin
  #{node['goatos']['home_dir']}/.config
  #{node['goatos']['home_dir']}/.local
  #{node['goatos']['home_dir']}/.local/share
  #{node['goatos']['home_dir']}/.cache
  #{node['goatos']['home_dir']}/.ssh
  #{node['goatos']['home_dir']}/lxc.conf.d
  #{node['goatos']['home_dir']}/recipes
  #{node['goatos']['home_dir']}/.config/lxc
  #{node['goatos']['home_dir']}/.local/share/lxc
  #{node['goatos']['home_dir']}/.local/share/lxcsnaps
  #{node['goatos']['home_dir']}/.cache/lxc
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

cookbook_file "#{node['goatos']['home_dir']}/bin/goatos-meta" do
  source 'goatos-meta.rb'
  mode 0700
  user node['goatos']['user']
  group node['goatos']['group']
end

cookbook_file "#{node['goatos']['home_dir']}/recipes/test.rb" do
  source 'test.rb'
  mode 0644
  user node['goatos']['user']
  group node['goatos']['group']
end

%w{serfx sshkey thor ruby-lxc lxc-extra}.each do |gem_name|
  execute "install_gem_#{gem_name}" do
    command "/opt/chef/embedded/bin/gem install --no-ri --no-rdoc #{gem_name}"
  end
end
