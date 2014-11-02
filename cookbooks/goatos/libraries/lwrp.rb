require 'chef/resource/lwrp_base'
require 'chef/provider/lwrp_base'
require 'chef/mixin/shell_out'
require 'json'

module GoatOS
  module RecipeHelper
    include Chef::Mixin::ShellOut

    def subuid_info
      ::File.read('/etc/subuid').scan(/goatos:(\d+):(\d+)/).flatten
    end

    def subgid_info
      ::File.read('/etc/subgid').scan(/goatos:(\d+):(\d+)/).flatten
    end

    def move_pids
      uid, _ = subuid_info
      gid, _ = subgid_info
      shell_out!('cgm create all goatos')
      shell_out!("cgm chown all goatos #{uid} #{gid}")
    end
  end

  module ProviderHelper
    Listener ||= Struct.new(:name, :listen, :port, :mode, :ip)
    def state_file
      '/opt/goatos/goats.json'
    end

    def compute_listeners
      return [] unless File.exist?(state_file)
      listeners = []
      metadata = JSON.parse(File.read(state_file))
      metadata['containers'].each do |n, meta|
        ct = LXC::Container.new(n, '/opt/goatos/.local/share/lxc')
        if ct.running?
          port, mode, listen = meta['expose'].split(':')
          config = Listener.new(n, listen, port, mode, ct.ip_addresses.first)
          listeners << config
        else
          Chef::Log.warn("LXC #{n} is absent, but its metadata is present")
        end
      end
      listeners
    end
  end
end

class Chef::Resource::HaproxyConfig < Chef::Resource::LWRPBase
  self.resource_name = :haproxy_config
  default_action :create
  actions :create, :delete
  attribute :path, kind_of: String, name_attribute: true, required: true
  attribute :disable_on_empty, kind_of: [TrueClass, FalseClass], default: true
  attribute :environment_file, kind_of: String, default: '/etc/default/haproxy'
end

class Chef::Provider::HaproxyConfig < Chef::Provider::LWRPBase

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    require 'lxc'
    extend GoatOS::ProviderHelper

    listeners =  compute_listeners
    enabled = '1'

    if listeners.empty? and new_resource.disable_on_empty
      enabled = '0'
    end

    file new_resource.environment_file do
      content "ENABLED=#{enabled}\n"
      mode 0644
      owner 'root'
      group 'root'
    end

    template new_resource.path do
      action :create
      mode 0644
      owner 'root'
      group 'root'
      source 'haproxy.cfg.erb'
      variables(listeners: listeners)
    end
  end

  action :delete do
    file new_resource.path do
      action :delete
    end

    file new_resource.environment_file do
      action :delete
    end
  end
end
