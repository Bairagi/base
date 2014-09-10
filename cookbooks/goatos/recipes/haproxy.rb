package 'haproxy'

file '/etc/default/haproxy' do
  content 'ENABLED=1'
  mode 0644
  owner 'root'
  group 'root'
  notifies :restart, 'service[haproxy]'
end

haproxy_config '/etc/haproxy/haproxy.cfg' do
  action :create
  notifies :reload, 'service[haproxy]'
end

service 'haproxy' do
  action [ :start, :enable]
  supports(
    restart: false,
    reload: false,
    status: false
  )
end
