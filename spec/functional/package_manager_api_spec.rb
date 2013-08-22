require 'spec_helper'
require 'rosh/host/package_managers/apt'
require 'rosh/host/package_managers/brew'
require 'rosh/host/package_managers/dpkg'
require 'rosh/host/package_managers/yum'


describe 'Package manager API' do
  shared_examples_for 'a package manager' do
    INSTANCE_METHODS =
      %i[
        create_package upgrade_packages update_definitions installed_packages
        _extract_updated_definitions _extract_upgraded_packages
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

  %i[Apt Brew Dpkg Yum].each do |package_manager|
    package_manager_class = Rosh::Host::PackageManagers.const_get package_manager

    describe package_manager_class do
      let(:shell) { double 'Rosh::Host::Shells::AShell' }
      subject { package_manager_class.new(shell) }
      it_behaves_like 'a package manager'
    end
  end
end
