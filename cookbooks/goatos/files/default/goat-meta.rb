#!/opt/chef/embedded/bin/ruby

require 'lxc'
require 'json'

def state_file
  '/opt/goatos/goats.json'
end

def container_metadata
  if File.exists?(state_file)
    collection = JSON.parse(File.read(state_file))
  else
    collection = {
      'containers'=> {},
      'last_updated' => nil
    }
  end
end

def add(name, key, value)
  update_ct!(name, key, value)
end

def expose(name, slp)
  add(name, 'expose', slp)
end

def update_ct!(name, key, value)
  collection = container_metadata
  if collection['containers'].key?(name)
    collection['containers'][name][key] = value
  else
    collection['containers'][name] = { key => value }
  end
  collection['last_updated'] = Time.now
  File.open(state_file, 'w') do |f|
    f.write(JSON.pretty_generate(collection))
  end
end


def container_list
  data = {}
  LXC.list_containers.each do |name|
    ct = LXC::Container.new(name)
    data[name] = {
      'ipaddress' => ct.ip_addresses.first
    }
  end
  data
end


def show
  live_containers = container_list
  metadata = container_metadata
  (live_containers.keys | metadata['containers'].keys ).each do |name|
    if live_containers.key?(name)
      ip = live_containers[name]['ipaddress']
    else
      ip = nil
    end
    puts "Containers"
    puts "---------------"
    puts "#{name} IP:#{ip} | Metadata: #{metadata['containers'][name]}"
  end
end


if $0 == __FILE__
  case ARGV.first
  when 'show'
    show
  when 'expose'
    expose(ARGV[1], ARGV[2])
  else
    raise 'Command not implemented'
  end
end
