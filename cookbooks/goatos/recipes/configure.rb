chef_gem "sshkey" do
  action :install
end

base 'lxc.conf' do
  title "lxc.conf"
  path '/opt/goatos/.config/lxc/default.conf'
  action :create
end

base 'lamp-template' do
  title "lamp.conf"
  path '/opt/goatos/.local/share/lxc/lamp-template/config'
  action :Create
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

ruby_block "enable haproxy" do
  block do
    line = 'ENABLED=0'
    newline = 'ENABLED=1'
    en = Chef::Util::FileEdit.new("/etc/default/haproxy")
    en.search_file_replace_line(/#{line}/, newline)
    en.write_file
  end
end

service "haproxy" do
  action :start
  ignore_failure :true
end
