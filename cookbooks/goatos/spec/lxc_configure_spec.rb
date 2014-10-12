require 'chefspec'

describe 'goatos::lxc_configure' do
  let(:chef_run) do
    stub_search("node", "roles:master").and_return([{'goatos' =>{'sshkey' => 'foobar'}}])
    ChefSpec::Runner.new do |node|
    end.converge(described_recipe)
  end

  it 'should create template for lxc configuration' do
    expect(chef_run).to create_template("/opt/goatos/.config/lxc/default.conf").with( user: 'goatos',
      group:  'goatos',
      mode:   0644
      )
  end

  it 'should create file for ssh authorized keys' do
    expect(chef_run).to create_file("/opt/goatos/.ssh/authorized_keys").with(
      user: 'goatos',
      group:  'goatos',
      mode:   0400,
      content: 'foobar'
    )
  end
end
