require 'spec_helper'
require 'rosh/host/package_managers/apt'
require 'rosh/host/package_managers/brew'
require 'rosh/host/package_managers/dpkg'
require 'rosh/host/package_managers/yum'


describe 'Package manager API' do
  shared_examples_for 'a package manager' do
    INSTANCE_METHODS =
      %i[
        bin_path create_package _installed_packages
        _update_definitions _extract_updated_definitions
        _upgrade_packages _extract_upgraded_packages
      ]

    OBSERVABLE_METHODS =
      %i[add_observer changed notify_observers]

    INSTANCE_METHODS.each do |meth|
      it "responds to instance method ##{meth.to_s}" do
        subject.should respond_to meth
      end
    end

    OBSERVABLE_METHODS.each do |meth|
      it "responds to observable method ##{meth.to_s}" do
        subject.should respond_to meth
      end
    end
  end

  %i[apt brew yum].each do |package_manager|
    describe package_manager do
      let(:shell) { double 'Rosh::Host::Shells::AShell' }
      before { allow(subject).to receive(:current_shell) { shell } }
      subject { Rosh::Host::PackageManager.new(package_manager, 'example.com') }
      it_behaves_like 'a package manager'
    end
  end
end
