require 'spec_helper'
require 'rosh/host'


describe Rosh::Host do
  let(:hostname) { 'test' }

  subject do
    Rosh::Host.new(hostname)
  end

  describe '#initialize' do
    its(:hostname) { should eq hostname }
  end
end
