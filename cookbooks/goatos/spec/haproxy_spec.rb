require 'chefspec'

describe 'goatos::haproxy' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'should install package haproxy' do
    expect(chef_run).to install_package 'haproxy'
  end


  it 'should start service haproxy' do
    expect(chef_run).to start_service 'haproxy'
  end


end
