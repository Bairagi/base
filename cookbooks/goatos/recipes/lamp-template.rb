directory '/opt/goatos/.local/share/lxc/lamp-template' do
  user node['goatos']['user']
  group node['goatos']['group']
  mode 0741
end

remote_file '/opt/goatos/.local/share/lxc/lamp-template/lamp-template.tar.gz' do
  source "https://s3.amazonaws.com/projspace/lamp-template.tar.gz"
  mode 0644
end

execute "extract-template" do
  comman "sudo tar --same-owner -xzf /opt/goatos/.local/share/lxc/lamp-template/lamp-template.tar.gz -C /opt/goatos/.local/share/lxc/lamp-template/"
end

base 'lamp-template' do
  title "lamp.conf"
  path '/opt/goatos/.local/share/lxc/lamp-template/config'
  action :create
end

