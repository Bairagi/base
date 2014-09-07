require 'thor'

module GoatOS
  class CLI < Thor
    class Lxc < Thor
      desc 'lxc ls', 'list all lxc'
      def ls
      end
    end
  end
end
