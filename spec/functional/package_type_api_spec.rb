require 'spec_helper'
require 'rosh/host/package_types/brew'
require 'rosh/host/package_types/deb'
require 'rosh/host/package_types/rpm'


describe 'Package type API' do
  shared_examples_for 'a package' do
    INSTANCE_METHODS =
      %i[
        _bin_path _info
        _install installed?
        _upgrade
        _at_latest_version? _current_version
        _remove
      ]

    INSTANCE_METHODS.each do |meth|
      it "responds to instance method ##{meth.to_s}" do
        subject.should respond_to meth
      end
    end
  end

  %i[Brew Deb Rpm].each do |package_type|
    describe package_type do
      let(:shell) { double 'Rosh::Host::Shells::AShell' }
      before { allow(subject).to receive(:current_shell) { shell } }

      subject do
        allow_any_instance_of(Rosh::Host::Package).to receive(:load_adapter)
        Rosh::Host::Package.new('test', 'api_test', 'example.com')
      end


      it_behaves_like 'a package'
    end
  end
end
