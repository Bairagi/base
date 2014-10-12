require 'chefspec'

describe 'goatos::lxc_install' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  %w{liblxc1 lxc lxc-dev lxc-templates python3-lxc cgmanager-utils build-essential}.each do |pkg|
    it "should install package #{pkg}" do
      expect(chef_run).to install_package(pkg)
    end
  end

  %w{ruby-lxc serfx sshkey thor chef-lxc}.each do |gem_name|
    it "should install gem package #{gem_name}" do
      expect(chef_run).to install_gem_package(gem_name).with( gem_binary: '/opt/chef/embedded/bin/gem' )
    end
  end

  it "should create user goatos" do
    expect(chef_run).to create_user("goatos").with( home: '/opt/goatos',
      shell: '/bin/bash'
      )
  end

  %W{ /opt/goatos/bin
      /opt/goatos/.config
      /opt/goatos/.local
      /opt/goatos/.local/share
      /opt/goatos/.cache
      /opt/goatos/.ssh
      /opt/goatos/lxc.conf.d
      /opt/goatos/recipes
      /opt/goatos/.config/lxc
      /opt/goatos/.local/share/lxc
      /opt/goatos/.local/share/lxcsnaps
      /opt/goatos/.cache/lxc}.each do |dir|
    it "should create directory #{dir} " do
          expect(chef_run).to create_directory(dir).with( user: 'goatos',
          group: 'goatos',
          mode:  0775 
        )
    end
  end

  it 'should create file to specify lxc-usrnet' do
    expect(chef_run).to create_file("/etc/lxc/lxc-usernet").with(
      user:   'root',
      group:  'root',
      mode:   0644,
      #content: 'foobar'
    )
  end

  it 'should create add cookbook file goatos-meta' do
    expect(chef_run).to create_cookbook_file("/opt/goatos/bin/goatos-meta").with(
      user:   'goatos',
      group:  'goatos',
      mode:   0700
    )
  end

  it 'should create add cookbook file goatos-meta' do
    expect(chef_run).to create_cookbook_file("/opt/goatos/recipes/test.rb").with(
      user:   'goatos',
      group:  'goatos',
      mode:   0644
    )
  end

  %w{serfx sshkey thor ruby-lxc lxc-extra}.each do |gem_name|
    it "should execute command to install gem package #{gem_name}" do
      expect(chef_run).to run_execute("/opt/chef/embedded/bin/gem install --no-ri --no-rdoc #{gem_name}")
    end
  end


end
