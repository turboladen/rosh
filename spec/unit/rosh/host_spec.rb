require 'spec_helper'
require 'rosh/host'


describe Rosh::Host do
  subject do
    Rosh::Host.new('test')
  end

  describe '#initialize' do
    its(:hostname) { should eq 'test' }
    its(:shell) { should be_a Rosh::RemoteShell }
  end
end
