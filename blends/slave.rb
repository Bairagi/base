require 'goatos_helper'
config(:ruby, stdout: $stdout)
config(:ssh, stdout: $stdout)
goatos = Blender::Configuration[:goatos]
members [goatos['master']]
ruby_task 'bootstrap' do
  execute do |h|
    extend GoatOS::Helper
    knife Chef::Knife::Bootstrap, h do |config|
      config[:ssh_user] = Blender::Configuration[:ssh]['user']
      config[:ssh_password] = Blender::Configuration[:ssh]['password']
      config[:ssh_port] = 22
      config[:chef_node_name] = 'sauron'
      config[:distro] = 'chef-full'
      config[:use_sudo] = true
      config[:use_sudo_password] = true
    end
  end
end

ruby_task 'set node run list' do
  execute do |h|
    extend GoatOS::Helper
    set_node 'sauron', run_list: 'role[install]'
  end
end

ssh_task 'run chef' do
  execute 'sudo chef-client --no-fork'
end

ruby_task 'Store SSH key' do
  execute do |h|
    extend GoatOS::Helper
    File.open('keys/sauron.rsa', 'w') do |f|
      f.write(show_node('sauron', attrs: 'goatos')['sshkey'])
      f.chmod(0600)
    end
  end
end

ruby_task 'set final run list' do
  execute do |h|
    extend GoatOS::Helper
    set_node 'sauron', run_list: 'role[slave]'
  end
end

ssh_task 'run chef' do
  execute 'sudo chef-client --no-fork'
end
