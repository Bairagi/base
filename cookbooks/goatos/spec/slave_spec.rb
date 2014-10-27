require 'chefspec'

describe 'goatos::slave' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

  it 'should include recipe haproxy' do
    expect(chef_run).to include_recipe 'goatos::haproxy'
  end

end
