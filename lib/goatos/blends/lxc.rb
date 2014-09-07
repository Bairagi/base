require 'goatos/blends/helper'
require 'blender/chef'

module GoatOS
  module Blends
    class Lxc
      def initialize(options = {})
        @config_file = options[:config_file]
        @search_term = options[:search_term] || '*:*'
        @search_attr = options[:search_attr] || 'ipaddress'
      end

      def run_blender(command)
        Blender.blend 'lxc', @config_file do |sched|
          sched.config(:chef, config_file: 'etc/knife.rb', attribute: @search_attr)
          sched.config(:ruby, stdout: $stdout)
          sched.config(:ssh, stdout: $stdout, user: 'goatos', keys: ['keys/sauron.rsa'])
          sched.members(sched.search(:chef, @search_term))
          sched.ssh_task command
        end
      end

      def ls
        run_blender('lxc-ls --fancy')
      end

      def create
        run_blender('lxc-create -n foo -t download -- -d ubuntu -a amd64 -r trusty')
      end

      def destroy
        run_blender('lxc-destroy -n foo -f')
      end

      def start
      end

      def stop
      end

      def restart
      end

      def spawn
        create
        start
      end
    end
  end
end

