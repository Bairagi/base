#!/opt/chef/embedded/bin/ruby

require 'lxc'
require 'json'
require 'thor'
module GoatOS
  module Meta
    class JSONStore
      attr_reader :state_file
      def initialize(state_file = '/opt/goatos/goats.json')
        @state_file = state_file
        @metadata = nil
      end
      def metadata
        @metadata ||= fetch_metadata
      end
      def fetch_metadata
        if File.exists?(state_file)
          collection = JSON.parse(File.read(state_file))
        else
          collection = { 'containers'=> {}, 'last_updated' => nil }
        end
      end
      def add(name, key, value)
        update!(name, key, value)
      end
      def expose(name, slp)
        add(name, 'expose', slp)
      end
      def update!(name, key, value)
        if metadata['containers'].key?(name)
          metadata['containers'][name][key] = value
        else
          metadata['containers'][name] = { key => value }
        end
        metadata['last_updated'] = Time.now
        File.open(state_file, 'w') do |f|
          f.write(JSON.pretty_generate(metadata))
        end
      end
      def containers
        LXC.list_containers.inject({}) do |data, name|
          ct = LXC::Container.new(name)
          data[name] = { 'ipaddress' => ct.ip_addresses.first } if ct.running?
        end
        data
      end
      def show(name)
        metadata['containers']['name']
      end
      def list
        metadata['containers']
      end
    end
    class CLI < Thor
      class_option :format,
        type: :string,
        aliases: '-F',
        description: 'Format output(test or json)',
        default: 'text'
      desc 'list', 'list all the metadata'
      def list
        store = JSONStore.new
        list = store.list
        case options[:format]
        when 'text'
          list.each do |name, meta|
            puts "#{name} | Metadata: #{meta.inspect}"
          end
        when 'json'
          puts JSON.pretty_generate(list)
        end
      end

      desc 'show NAME', 'show metadata of a single container'
      def show(name)
        store = JSONStore.new
        meta = store.list[name]
        case options[:format]
        when 'text'
          puts "#{name} | Metadata: #{meta.inspect}"
        when 'json'
          puts JSON.pretty_generate(meta)
        end
      end

      desc 'expose NAME SLP', 'Expose container port via host'
      def expose(name, slp)
        store = JSONStore.new
        store.expose(name, slp)
      end
    end
  end
end

if $0 == __FILE__
  GoatOS::Meta::CLI.start(ARGV)
end
