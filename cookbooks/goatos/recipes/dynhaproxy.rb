r = chef_gem "ruby-lxc" do
  action :nothing
end

r.run_action(:install)
Gem.clear_paths

base_haproxy 'haproxy.cfg' do
  title "haproxy.cfg"
  path '/etc/haproxy/haproxy.cfg'
  action :create
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

service "haproxy" do
  supports :status => true
  action :start
end

service "haproxy" do
  supports :status => false
  action :reload
end
