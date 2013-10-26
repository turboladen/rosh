require 'spec_helper'
require 'rosh'


describe 'Package Management' do
  shared_examples 'a package manager' do
    #before(:all) do
    #  `vagrant up #{vagrant_box_name}`
    #end

    #after(:all) do
    #  `vagrant halt #{vagrant_box_name}`
    #end

    it 'can install and remove the package' do
      if host.packages[package_name].installed?
        host.su do
          host.packages[package_name].remove
        end

        expect(host.packages[package_name].installed?).to eq true
      end

      host.su do
        host.packages[package_name].install
        expect(host.packages[package_name].installed?).to eq true

        host.packages[package_name].remove
        expect(host.packages[package_name].installed?).to eq false
      end
    end
  end

  context 'on CentOS 5.6 x86_64' do
    it_behaves_like 'a package manager' do
      before do
        Rosh.add_host('192.168.33.100', host_label: :centos_57_64, user: 'vagrant',
          keys: [Dir.home + '/.vagrant.d/insecure_private_key'])
      end

      let(:host) { Rosh.hosts[:centos_57_64] }
      let(:vagrant_box_name) { 'centos_57_64' }
      let(:package_name) { 'curl' }
    end
  end
end
