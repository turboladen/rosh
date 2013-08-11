require 'spec_helper'
require 'rosh/host/package_types/brew'
require 'rosh/host/package_types/deb'
require 'rosh/host/package_types/rpm'


describe 'Package type API' do
  shared_examples_for 'a package' do
    ATTRIBUTES =
      %i[name version status]

    INSTANCE_METHODS =
      %i[info installed? install at_latest_version? current_version remove upgrade]

    OBSERVABLE_METHODS =
      %i[add_observer changed notify_observers]

    ATTRIBUTES.each do |meth|
      it "responds to accessor ##{meth.to_s}" do
        subject.should respond_to meth
      end
    end

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

  %i[Brew Deb Rpm].each do |package_type|
    package_type_class = Rosh::Host::PackageTypes.const_get package_type

    describe package_type_class do
      let(:shell) { double 'Rosh::Host::Shells::AShell' }
      subject { package_type_class.new('api_test', shell) }
      it_behaves_like 'a package'
    end
  end
end
