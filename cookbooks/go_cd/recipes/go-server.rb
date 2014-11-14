# Cookbook Name:: go_cd
# Recipe:: go-server


%w{openjdk-7-jdk unzip}.each do |pkg|
  package pkg
end

remote_file "#{Chef::Config[:file_cache_path]}/go-server.deb" do
  source  node['go-server']['download_url']
end

dpkg_package "go-server" do
  source "#{Chef::Config[:file_cache_path]}/go-server.deb"
  action :install
end

service "go-server" do
  action [ :enable, :start ]
  supports :status => true, :start => true, :stop => true, :restart => true
end

