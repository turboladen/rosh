require 'spec_helper'
require 'rosh/host/package_manager'


describe Rosh::Host::PackageManager do
  let(:shell) { double 'Rosh::Host::Shell' }

  subject do
    Rosh::Host::PackageManager.new(shell)
  end

  describe '#[]' do
    it 'calls #create with the package name' do
      subject.should_receive(:create).with('test')
      subject['test']
    end
  end
end
