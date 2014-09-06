require 'goatos/log'
require 'highline/import'
require 'goatos/builder'

module GoatOS
  class CLI

    include Mixlib::CLI
    include Builder

    option :target,
      short: '-t TARGET',
      long: '--target TARGET',
      required: true,
      description: 'Target host IP/FQDN'


    option :user,
      short: '-u USER',
      long: '--user USER',
      required: true,
      description: 'SSH user name'

    option :name,
      short: '-N NAME',
      long: '--name NAME',
      description: 'chef node name of the node (default sauron)',
      default: 'sauron'

    option :bootstrap,
      short: '-b master',
      long: '--bootstrap master',
      default: 'standalone',
      description: 'Bootstrap a node  (can be "master" or "slave" or "standalone")'


    def bootstrap(cwd = Dir.pwd)
      Dir.chdir(cwd) do
        case config[:bootstrap]
        when 'master'
          build_master
        when 'slave'
          build_slave
        when 'standalone'
          build_standalone
        else
          abort 'only master, slave or standalone bootstrap is valid'
        end
      end
    end
  end
end
