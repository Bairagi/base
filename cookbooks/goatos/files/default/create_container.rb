#!/opt/chef/embedded/bin/ruby
require 'lxc'
require 'lxc-extra'
require 'mixlib/cli'

class Container
  include Mixlib::CLI

  option :name,
    :short => "-n name",
    :long => "--name name",
    :required => true,
    :description => "Name of the container to be created"

  option :type,
    :short => "-t type",
    :long => "--type type",
    :required => true,
    :description => "Type of the container to be created"

  option :memory,
    :short => "-m memory",
    :long => "--memory memory",
    :default => '256M',
    :description => "Memory to be allocated to the container"

  option :cpus,
    :short => "-c cpus",
    :long => "--cpus cpus",
    :default => '0',
    description => "number of cpus to be allocated for the container"

  option :help,
    :short => "-h",
    :long => "--help"
    :description => "Show this message",
    :on => :tail,
    :boolean => true,
    :show_options => true,
    :exit => 0

  attr_accessor :name, :type, :memory, :cpus

  def initialize(args)
    @container_info = {
      name: args[0],
      type: args[1],
      memory: args[2],
      cpus: args[3],
    }

    container = new_container(@container_info[:type])
    container.clone(@container_info[:name], flags: LXC::LXC_CLONE_SNAPSHOT, bdev_type: 'overlayfs' )
  end

  def new_container(param)
    LXC::Container.new(param)
  end

  def create_and_start
    @container = new_container(@container_info[:name])
    @container.start
    sleep(5)
  end

  def set_cgroup_limits
    @container.set_cgroup_item("memory.limit_in_bytes", @container_info[:memory])
    @container.set_cgroup_item("cpuset.cpus", @container_info[:cpus])
  end

  def attach
    @container.execute do
    #run custom commands inside containers
    end
  end

  def ips
    @container.ip_addresses
  end

end


arguments = ARGV

if arguments.length == 4
  puts "You have passed correct number of arguments."
  container = Container.new(arguments)
  container.create_and_start
  container.set_cgroup_limits
  container.attach
  puts container.ips
else
  puts "Please check the number of arguments passed, it should be four arguments maximum."
end
