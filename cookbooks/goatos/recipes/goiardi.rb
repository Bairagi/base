user 'goiardi' do
  system true
end

%w{postgresql-9.3 postgresql-client-9.3}.each do |pkg|
  package pkg
end

service 'postgresql'

execute 'create_postgres_user' do
  command 'createuser goiardi -w'
  user 'postgres'
  action :nothing
end

execute 'create_postgres_db' do
  command 'createdb goiardi -O goiardi'
  user 'postgres'
  action :nothing
end

cookbook_file '/etc/postgresql/9.3/main/pg_hba.conf' do
  owner 'postgres'
  group 'postgres'
  mode 0640
  notifies :restart, 'service[postgresql]', :immediately
  notifies :run, 'execute[create_postgres_user]', :immediately
  notifies :run, 'execute[create_postgres_db]', :immediately
end

remote_file '/usr/bin/goiardi' do
  source node['goatos']['goiardi_url']
  checksum node['goatos']['goiardi_binary']
  mode 0755
end

%w{/etc/goiardi /var/goiardi /var/goiardi/file_checksums}.each do |dir|
  directory dir do
    owner 'goiardi'
    group 'goiardi'
    mode 0755
  end
end

template '/etc/goiardi/goiardi.conf' do
  owner 'root'
  group 'goiardi'
  mode 0644
  source 'goiardi.conf.erb'
  variables(ip: node['goatos']['goiardi_ip'])
end

execute 'scrub_sql_1' do
  command "sed -i 's/REVOKE ALL ON SCHEMA public FROM jeremy;/REVOKE ALL ON SCHEMA public FROM goiardi;/' /tmp/goiardi.sql"
  action :nothing
end

execute 'scrub_sql_2' do
  command "sed -i 's/GRANT ALL ON SCHEMA public TO jeremy;/GRANT ALL ON SCHEMA public TO goiardi;/' /tmp/goiardi.sql"
  action :nothing
end

execute 'restore_db' do
  user 'goiardi'
  command 'psql goiardi -f /tmp/goiardi.sql'
  action :nothing
end

remote_file '/tmp/goiardi.sql' do
  source 'https://raw.githubusercontent.com/ctdk/goiardi/master/sql-files/goiardi-schema-postgres.sql'
  action :create_if_missing
  notifies :run, 'execute[scrub_sql_1]', :immediately
  notifies :run, 'execute[scrub_sql_2]', :immediately
  notifies :run, 'execute[restore_db]', :immediately
end

cookbook_file '/etc/init.d/goiardi' do
  owner 'goiardi'
  group 'goiardi'
  mode 0750
  source 'goiardi.init.sh'
end

service 'goiardi' do
  action :start
  supports(start: true, restart: true, stop: true, status: true)
end
