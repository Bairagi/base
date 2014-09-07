
u_start, u_range = ::File.read('/etc/subuid').scan(/goatos:(\d+):(\d+)/).flatten
g_start, g_range = ::File.read('/etc/subgid').scan(/goatos:(\d+):(\d+)/).flatten

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
end

file '/opt/goatos/.ssh/authorized_keys' do
  owner node['goatos']['user']
  group node['goatos']['group']
  mode 0400
  content search(:node, 'roles:master').first['goatos']['sshkey']
end
