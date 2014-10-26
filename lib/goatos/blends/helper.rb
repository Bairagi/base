require 'goatos/log'
require 'chef/config'
require 'chef/node'
require 'net/scp'

module GoatOS
  module Blends
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

      def chef_node(name)
        configure
        node = load_node(name)
        yield node if block_given?
      end

      def set_chef_node_run_list(name, run_list)
        chef_node(name) do |node|
          node.run_list.reset!
          node.run_list << run_list
          node.save
        end
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
end
