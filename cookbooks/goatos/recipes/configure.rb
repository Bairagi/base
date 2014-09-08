extend GoatOS::RecipeHelper
u_start, u_range = subuid_info
g_start, g_range = subgid_info

template '/opt/goatos/.config/lxc/default.conf' do
  owner node['goatos']['user']
  group node['goatos']['group']
  mode 0644
  source 'lxc.conf.erb'
  variables(
    u_start: u_start,
    u_range: u_range,
    g_start: g_start,
    g_range: g_range
  )
  notifies :run, 'ruby_block[move_cgroup]'
end

ruby_block 'move_cgroup' do
  block do
    extend GoatOS::RecipeHelper
    move_pids
  end
  action :nothing
end

file '/opt/goatos/.ssh/authorized_keys' do
  owner node['goatos']['user']
  group node['goatos']['group']
  mode 0400
  content search(:node, 'roles:master').first['goatos']['sshkey']
end
