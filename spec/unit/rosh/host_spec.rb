require 'spec_helper'
require 'rosh/host'


describe Rosh::Host do
  let(:name) { 'test' }

  subject do
    Rosh::Host.new(name)
  end

  describe '#initialize' do
    before do
      Rosh::Host::Shells::Remote.should_receive(:new)
    end

    its(:name) { should eq name }
  end
end
