require 'spec_helper'
require 'rosh'


shared_examples_for 'a package manager' do
  before do
    if host.packages[package_name].installed?
      host.su do
        host.packages[package_name].remove
      end

      expect(host.packages[package_name].installed?).to eq false
    end
  end

  after do
    if host.packages[package_name].installed?
      host.su do
        host.packages[package_name].remove
      end

      expect(host.packages[package_name].installed?).to eq false
    end
  end

  it 'can install and remove the package' do
    host.su do
      host.packages[package_name].install
      expect(host.packages[package_name].installed?).to eq true

      host.packages[package_name].remove
      expect(host.packages[package_name].installed?).to eq false
    end
  end

  it 'installs the latest version of the package' do
    host.su do
      host.packages[package_name].install

      expect(host.packages[package_name].at_latest_version?).to eq true
    end
  end
end


describe 'Package Management' do
  before(:all) do
    Rosh.reset

    Rosh.add_host('192.168.33.100', host_label: :centos_57_64, user: 'vagrant',
      keys: [Dir.home + '/.vagrant.d/insecure_private_key'])
    Rosh.add_host('192.168.33.102', host_label: :debian_squeeze_32, user: 'vagrant',
      keys: [Dir.home + '/.vagrant.d/insecure_private_key'])
  end

  let(:package_name) { 'curl' }

  context 'centos' do
    it_behaves_like 'a package manager' do
      let(:host) do
        Rosh.hosts[:centos_57_64]
      end
    end
  end

  context 'debian' do
    it_behaves_like 'a package manager' do
      let(:host) do
        Rosh.hosts[:debian_squeeze_32]
      end
    end
  end
end
