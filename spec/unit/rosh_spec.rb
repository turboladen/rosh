require 'spec_helper'
require 'rosh'

describe Rosh do
  describe '#initialize' do
    its(:hosts) { should be_empty }
  end

  describe '#add_host' do
    let(:host) do
      double 'Rosh::Host'
    end

    it 'creates a Host by the given hostname and adds it to the list of hosts' do
      Rosh::Host.should_receive(:new).and_return(host)

      subject.add_host('test')
      subject.hosts.should == { 'test' => host }
    end
  end
end
