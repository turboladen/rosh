require 'spec_helper'
require 'rosh/host'


describe Rosh::Host do
  let(:hostname) { 'test' }

  subject do
    Rosh::Host.new(hostname)
  end

  describe '#initialize' do
    before do
      Rosh::Host::Shells::Remote.should_receive(:new)
    end

    its(:hostname) { should eq hostname }
  end
end
