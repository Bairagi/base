require 'chefspec'

describe 'go_cd::server' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  %w{openjdk-7-jdk unzip }.each do |pkg|
    it "should install package #{pkg} required for go-server" do
      expect(chef_run).to install_package(pkg)
    end
  end

  it 'should download go-server installer using remote file' do
    expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/go-server.deb").with(
      source: 'http://download.go.cd/gocd-deb/go-server-14.2.0-377.deb'
      )
  end

  it 'should install dpkg package go-server' do
    expect(chef_run).to install_dpkg_package('go-server')
  end

  it 'should enable go-server service' do
    expect(chef_run).to enable_service('go-server')
  end

  it 'should start go-server service' do
    expect(chef_run).to start_service('go-server')
  end
end
