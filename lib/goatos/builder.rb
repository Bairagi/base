require 'goatos/blends/master'

module GoatOS
  module Builder
    def build_master
      Blends::Master.build
    end
    def build_slave
      Blends::Slave.build
    end
    def build_standalone
      Blends::Master.build
      Blends::Slave.build
    end
  end
end
