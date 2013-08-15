require 'spec_helper'
require 'rosh/host/package_manager'


describe Rosh::Host::PackageManager do
  let(:shell) { double 'Rosh::Host::Shell::Fakie' }

  let(:adapter) do
    double 'Rosh::Host::PackageManager::Fakie'
  end

  subject do
    pm = Rosh::Host::PackageManager.new('testie', 'meow', shell)
    pm.stub(:adapter).and_return adapter

    pm
  end

  describe '#[]' do
    it 'calls #create with the package name' do
      adapter.should_receive(:create_package).with('test')
      subject['test']
    end
  end
end
