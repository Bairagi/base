package 'haproxy'

haproxy_config '/etc/haproxy/haproxy.cfg' do
  environment_file '/etc/default/haproxy'
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
