directory '/opt/goatos/.local/share/lxc/lamp-template' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0741
end

remote_file '/opt/goatos/.local/share/lxc/lamp-template/lamp-template.tar.gz' do
  source "https://s3.amazonaws.com/projspace/lamp-template.tar.gz"
  mode 0644
  not_if do ::File.exists?('/opt/goatos/.local/share/lxc/lamp-template/lamp-template.tar.gz') end
end

execute "extract-template" do
  command "sudo tar --same-owner -xzf /opt/goatos/.local/share/lxc/lamp-template/lamp-template.tar.gz -C /opt/goatos/.local/share/lxc/lamp-template/"
  not_if do ::File.directory?('/opt/goatos/.local/share/lxc/lamp-template') end
end

goatos_lxc_config 'lamp-template' do
  title "lamp.conf"
  path '/opt/goatos/.local/share/lxc/lamp-template/config'
  action :create
end

