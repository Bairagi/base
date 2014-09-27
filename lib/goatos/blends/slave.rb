require 'goatos/blends/helper'

module GoatOS
  module Blends
    module Slave
      def add_slave_tasks(sched, options )
        sched.ssh_task 'sudo apt-get update -y'
        sched.ssh_task 'sudo chef-client --no-fork -o recipe[goatos::lxc_install]'
        sched.ssh_task 'sudo chef-client --no-fork -o recipe[goatos::lxc_configure]'
        sched.ssh_task 'reboot instance' do
          execute 'sudo reboot'
          ignore_failure true
        end
        sched.ruby_task 'sleep 90s' do
          execute do |h|
            sleep 90
          end
        end
      end
    end
  end
end
