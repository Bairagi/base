require 'chef/resource/lwrp_base'
require 'chef/provider/lwrp_base'
require 'chef/mixin/shell_out'

module GoatOS
  module RecipeHelper

    extend Chef::Mixin::ShellOut

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
end
