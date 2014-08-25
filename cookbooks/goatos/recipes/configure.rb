chef_gem "sshkey" do
  action :install
end

require 'sshkey'

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

unless ::File.exist?('/opt/goatos/.ssh/authorized_keys')
  k = SSHKey.generate
  file '/opt/goatos/.ssh/authorized_keys' do
    owner node['goatos']['user']
    group node['goatos']['group']
    mode 0400
    content k.ssh_public_key
  end
  node.set['goatos']['sshkey'] = k.private_key
end

execute "cgroups" do
  command "sudo cgm create all goatos && sudo cgm chown all goatos $(id -u goatos) $(id -g goatos)"
end

ruby_block "edit bashrc" do
  block do
   line = 'source /opt/goatos/lxc.conf.d/cgmmove'
   brc = Chef::Util::FileEdit.new("/opt/goatos/.bashrc")
   brc.insert_line_if_no_match(/#{line}/, line)
   brc.write_file
  end
end
