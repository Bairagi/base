require 'goatos/builder'

module GoatOS
  class Runner
    include Builder
    attr_reader :conf_dir
    attr_reader :repo_dir

    def initialize(opts = {})
      @conf_dir = opts[:conf_dir] || default_conf_dir
      @repo_dir = opts[:repo_dir] || default_repo_dir
    end

    def bootstrapped?
      File.exist?(repo_dir) and File.exist?(conf_dir)
    end

    def provision(opts)
      Dir.chdir(repo_dir) do
        case opts[:type]
        when 'master'
          build_master( opts )
        when 'slave'
          build_slave( opts )
        when 'standalone'
          build_standalone( opts )
        else
          abort 'only master, slave or standalone bootstrap is valid'
        end
      end
    end

    def default_repo_dir
      if ENV['HOME']
        File.join(ENV['HOME'], '.goatos', 'repo')
      else
        '/var/lib/goatos/repo'
      end
    end

    def default_conf_dir
      if ENV['HOME']
        File.join(ENV['HOME'], '.goatos', 'conf')
      else
        '/etc/goatos'
      end
    end

    def create_repo
      Dir.mkdir_p(repo_dir) unless File.exist?(repo_dir)
      Dir.chdir(repo_dir) do
        %w{cookbooks keys roles environments etc}.each do |dir|
          unless File.exist?(dir)
            Dir.mkdir(dir)
          end
        end
        Dir["#{File.expand_path('../../../roles', __FILE__)}/*.rb"].each do |f|
          FileUtils.cp( f, "roles/#{File.basename(f)}")
        end
        Dir["#{File.expand_path('../../../cookbooks', __FILE__)}/*"].each do |f|
          FileUtils.cp_r( f, "cookbooks/#{File.basename(f)}")
        end
      end
    end

    def run_blender(command, ssh_opts, chef_opts)
      Blender.blend('goatos_run_chef') do |sched|
        sched.config(
          :chef,
          config_file: File.join(conf_dir, 'knife.rb'),
          attribute: chef_opts[:attribute]
        )
        sched.config(:ruby, stdout: $stdout)
        sched.config(:ssh, ssh_opts.merge(stdout: $stdout))
        sched.members(sched.search(:chef, chef_opts[:filter]))
        sched.ssh_task command
      end
    end

    # create_machine(name, options[:cloud], ssh_port)
    def create_machine(name, config_file, ssh_port)
      require 'goatos/cloud'
      require 'goatos/cloud/providers/digital_ocean'
      config = YAML.load(File.read( config_file ))
      klass = GoatOS::Cloud.provider(config['provider'])
      provisioner = klass.new(config['credentials'])
      machine_options = config['machine_options']
      details = provisioner.create(options[:name], machine_options)
      puts "Waiting till host becomes reachable"
      until host_reachable?(details[:host], ssh_port )
        sleep 10
        print '.'
      end
      details
    end

    def host_reachable?(host, port)
      socket = TCPSocket.new(host, port)
      if IO.select([socket], nil, nil, 5)
        banner = socket.gets
        banner and !banner.empty?
      else
        false
      end
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError, Errno::EPERM, Errno::ETIMEDOUT, Errno::ECONNRESET
      false
    ensure
      socket && socket.close
    end
  end
end
