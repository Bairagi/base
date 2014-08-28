#!/opt/chef/embedded/bin/ruby
require 'lxc'

def number_of_containers
  c = LXC::list_containers().size
  puts c
end

number_of_containers

