require 'chef/knife/bootstrap'
require 'chef/knife/cookbook_upload'
require 'chef/knife/role_from_file'

module GoatOS
  module Helper
    extend self

    master = Blender::Configuration[:goatos]['master']
    Chef::Config[:client_key] = 'keys/admin.pem'
    Chef::Config[:node_name] = 'admin'
    Chef::Config[:chef_server_url] = "https://#{master}"
    Chef::Config[:validation_key] = 'keys/chef-validator.pem'

    def knife(klass, *args)
      klass.load_deps
      plugin = klass.new
      plugin.name_args = args
      yield plugin.config if block_given?
      plugin.run
    end

    def set_node(name, opts ={})
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
      Chef::Node.load(name)
    end

    def show_node(name, opts = {})
      node = load_node(name)
      if opts[:attrs]
        node[opts[:attrs]]
      end
    end
  end
end
