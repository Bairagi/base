package 'liblxc1'
package 'lxc'
package 'lxc-dev'
package 'lxc-templates'
package 'python3-lxc'
package 'build-essential'
package 'haproxy'
package 'cgmanager-utils'

gem_package 'ruby-lxc' do
  gem_binary '/opt/chef/embedded/bin/gem'
end

gem_package 'lxc-extra' do
  gem_binary '/opt/chef/embedded/bin/gem'
end

gem_package 'sshkey' do
  gem_binary '/opt/chef/embedded/bin/gem'
end

gem_package 'serfx' do
  gem_binary '/opt/chef/embedded/bin/gem'
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

cookbook_file "/usr/local/bin/create_container.rb" do
  owner "root"
  group "root"
  mode 0755
  source "create_container.rb"
end

cookbook_file "/usr/local/bin/number_of_containers.rb" do
  owner "root"
  group "root"
  mode 0755
  source "number_of_containers.rb"
end

file '/opt/goatos/lxc.conf.d/cgmmove' do
  owner 'goatos'
  group 'goatos'
  mode 0755
  content "cgm movepid all #{node['goatos']['user']} $$ > /dev/null 2>&1"
end
