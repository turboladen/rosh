require 'rosh'

RSpec.shared_examples_for 'a service manager' do
  before do
    unless host.services[service].exists?
      host.su do
        host.packages[package].install
      end
    end
  end

  it 'can list services' do
    list = host.services.list

    list.each do |service|
      expect(service).to be_a Rosh::ServiceManager::Service
    end
  end

  it 'can get the status of a service' do
    expect(host.services[service].status).to_not be_nil
  end

  it 'can get info about the service' do
    expect(host.services[service].info).to_not be_nil
  end

  it 'can start and stop a service' do
    host.su do
      host.services[service].start
      expect(host.services[service].status).to eq :running
      expect(host.services[service]).to be_started

      host.services[service].stop
      expect(host.services[service].status).to eq :stopped
      expect(host.services[service]).to be_stopped
    end
  end
end

RSpec.describe 'Service Management' do
  include_context 'hosts'

  context 'centos' do
    it_behaves_like 'a service manager' do
      let(:package) { 'vixie-cron' }
      let(:service) { 'crond' }
      let(:host) { Rosh.hosts[:centos_57_64] }
    end
  end

  context 'debian' do
    it_behaves_like 'a service manager' do
      let(:package) { 'cron' }
      let(:service) { 'cron' }
      let(:host) { Rosh.hosts[:debian_squeeze_32] }
    end
  end

  context 'localhost' do
    it_behaves_like 'a service manager' do
      let(:package) { 'cron' }
      let(:service) { 'cron' }
      let(:host) { Rosh.hosts['localhost'] }
    end
  end
end

