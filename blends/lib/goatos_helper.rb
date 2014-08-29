require 'chef/knife/bootstrap'
require 'chef/knife/cookbook_upload'
require 'chef/knife/role_from_file'
require 'goatos/log'

module GoatOS
  module Helper
    extend self
    def configure
      if File.exist?('etc/knife.rb')
        Log.info('Configuring using knife config')
        Chef::Config.from_file 'etc/knife.rb'
      else
        Log.info('Configuring using raw values')
        Chef::Config[:client_key] = 'keys/admin.pem'
        Chef::Config[:node_name] = 'admin'
        Chef::Config[:chef_server_url] = "https://#{Blender::Configuration[:goatos]['target']}"
        Chef::Config[:validation_key] = 'keys/chef-validator.pem'
      end
    end

    def knife(klass, *args)
      configure
      klass.load_deps
      plugin = klass.new
      plugin.name_args = args
      yield plugin.config if block_given?
      plugin.run
    end

    def set_node(name, opts ={})
      configure
      node = load_node(name)
      if opts[:run_list]
        node.run_list.reset!
        Array(opts[:run_list]).each do |item|
          node.run_list << item
        end
      end
      node.save
    end

    def load_node(name)
      configure
      Chef::Node.load(name)
    end

    def fetch_node(name, opts = {})
      configure
      node = load_node(name)
      if opts[:attrs]
        node[opts[:attrs]]
      end
    end
  end
end
