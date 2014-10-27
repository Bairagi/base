require 'chefspec'

describe 'goatos::goiardi' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }
  it 'should create user goiardi' do
    expect(chef_run).to create_user('goiardi').with(
      system: true
    )
  end
  it 'should install postgres packages' do
    expect(chef_run).to install_package('postgresql-9.3')
    expect(chef_run).to install_package('postgresql-client-9.3')
  end
  it 'should create postgres config file' do
    expect(chef_run).to create_cookbook_file('/etc/postgresql/9.3/main/pg_hba.conf').with(
    owner: 'postgres',
    group: 'postgres',
    mode: 0640
    )
    conf = chef_run.cookbook_file('/etc/postgresql/9.3/main/pg_hba.conf')
    expect(conf).to notify('service[postgresql]').to(:restart).immediately
    expect(conf).to notify('execute[create_postgres_user]').to(:run).immediately
    expect(conf).to notify('execute[create_postgres_db]').to(:run).immediately
  end
  it 'should install goiardi binary' do
    expect(chef_run).to create_remote_file('/usr/bin/goiardi')
  end
  it 'should create goiardi directories' do
    %w{/etc/goiardi /var/goiardi /var/goiardi/file_checksums}.each do |dir|
      expect(chef_run).to create_directory(dir).with(
        owner: 'goiardi',
        group: 'goiardi',
        mode: 0755
      )
    end
  end
  it 'should create goiardi config' do
    expect(chef_run).to create_template('/etc/goiardi/goiardi.conf').with(
      owner: 'root',
      group: 'goatos',
      mode: 0644,
      source: 'goiardi.conf.erb',
      variables: { ip: '10.0.3.1' }
    )
  end
  it 'should create goiardi init script' do
    expect(chef_run).to create_cookbook_file('/etc/init.d/goiardi').with(
      owner: 'goiardi',
      group: 'goiardi',
      mode: 0750,
      source: 'goiardi.init.sh'
    )
  end
  it 'should start goiardi service' do
    expect(chef_run).to start_service('goiardi').with(
      supports: {start: true, restart: true, stop: true, status: true}
    )
  end
end
