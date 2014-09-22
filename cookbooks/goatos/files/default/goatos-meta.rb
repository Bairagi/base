#!/opt/chef/embedded/bin/ruby

require 'lxc'
require 'lxc/extra'
require 'json'
require 'thor'
require 'mixlib/shellout'

module GoatOS
  module Meta
    CtMetadata = Struct.new(
      :name,
      :template,
      :release,
      :arch,
      :distro,
      :expose,
      :chef_recipe
    ) do
      if RUBY_VERSION < '2.1.1'
        def to_h
          Hash[ each_pair.to_a ]
        end
      end
    end
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
        collection = { 'containers'=> {}, 'last_updated' => nil }
        if File.exists?(state_file)
          data = JSON.parse(File.read(state_file))
          data['containers'].each do |name, meta|
            collection['containers'][name] = CtMetadata.new(*meta.values)
          end
          collection['last_updated'] = data['last_updated']
        end
        collection
      end
      def add(name, meta)
        unless get(name).nil?
          raise RuntimeError, "Container '#{name}' already present"
        end
        metadata['containers'][name]= meta
        write_to_disk
      end

      def write_to_disk
        cts = {'containers'=> {}}
        metadata['containers'].each do |n, meta|
          cts['containers'][n] = meta.to_h
        end
        cts['last_updated'] = Time.now
        File.open(state_file, 'w') do |f|
          f.write(JSON.pretty_generate(cts))
        end
      end

      def get(name)
        metadata['containers'][name]
      end
      def delete(name)
        metadata['containers'].delete(name)
        write_to_disk
      end
      def list
        metadata['containers']
      end
    end
    class CLI < Thor
      def self.exit_on_failure?
        true
      end
      class_option :format,
        type: :string,
        aliases: '-F',
        description: 'Format output(test or json)',
        default: 'text'

      desc 'converge CONTAINER', 'Converge a chef recipe inside the container'
      def converge(container)
        store = JSONStore.new
        recipe = store.get(container).chef_recipe
        recipe_path = "/opt/goatos/recipes/#{recipe}.rb"
        recipe_text = File.read(recipe_path)
        Chef::Config[:solo] = true
        ct = ::LXC::Container.new(container)
        Chef::Log.init(STDOUT)
        Chef::Log.level = :info
        client = Class.new(Chef::Client) do
          def run_ohai
            ohai.run_plugins
          end
        end.new
        client.ohai.load_plugins
        ct.execute do
          client.run_ohai
          client.load_node
          client.build_node
          run_context = Chef::RunContext.new(client.node, {}, client.events)
          recipe = Chef::Recipe.new('goatos_lxc', recipe, run_context)
          recipe.instance_eval(recipe_text, recipe_path, 1)
          runner = Chef::Runner.new(run_context)
          runner.converge
        end
      end

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
        meta = store.get(name)
        case options[:format]
        when 'text'
          puts "#{name} | Metadata: #{meta.inspect}"
        when 'json'
          puts JSON.pretty_generate(meta.to_h)
        end
      end

      desc 'add NAME', 'Add a container info in the metadata'
      option :template,
        default: 'download',
        aliases: '-t',
        description: 'Template for building rootfs'
      option :arch,
        default: 'amd64',
        aliases: '-a',
        description: 'ARCH for the lxc'
      option :distro,
        default: 'ubuntu',
        aliases: '-d',
        description: 'Disro type to be used with download template'
      option :chef_recipe,
        aliases: '-R',
        description: 'A chef recipe that will be executed upon container start'
      option :release,
        default: 'trusty',
        aliases: '-r',
        description: 'Release of a distribution (e.g lucid, precise, trusty for ubuntu)'
      option :expose,
        aliases: '-e',
        description: 'Expose container port'
      def add(name)
        store = JSONStore.new
        meta = CtMetadata.new(
          name,
          options[:template],
          options[:release],
          options[:arch],
          options[:distro],
          options[:expose],
          options[:chef_recipe]
        )
        store.add(name, meta)
      end
      desc 'delte CONTAINER_NAME', 'delete container meta data'
      def delete(name)
        store = JSONStore.new
        store.delete(name)
      end
    end
  end
end

if $0 == __FILE__
  GoatOS::Meta::CLI.start(ARGV)
end
