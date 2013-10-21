require 'spec_helper'
require 'rosh/host/package_types/brew'
require 'rosh/host/package_types/deb'
require 'rosh/host/package_types/rpm'


describe 'Package type API' do
  shared_examples_for 'a package' do
    PUBLIC_INSTANCE_METHODS =
      %i[bin_path info installed? at_latest_version? current_version]

    PRIVATE_INSTANCE_METHODS =
      %i[default_bin_path install_package upgrade_package remove_package]

    OBSERVABLE_METHODS =
      %i[add_observer changed notify_observers]

    PUBLIC_INSTANCE_METHODS.each do |meth|
      it "responds to public instance method ##{meth.to_s}" do
        subject.should respond_to meth
      end
    end

    PRIVATE_INSTANCE_METHODS.each do |meth|
      it "responds to private instance method ##{meth.to_s}" do
        subject.respond_to?(meth, true).should be_true
      end
    end

    OBSERVABLE_METHODS.each do |meth|
      it "responds to observable method ##{meth.to_s}" do
        subject.should respond_to meth
      end
    end
  end

  %i[brew deb rpm].each do |package_type|
    describe package_type do
      subject do
        Rosh::Host::Package.new(package_type, 'api_test', 'example.com')
      end

      it_behaves_like 'a package'
    end
  end
end
