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

    before do
      Rosh::Host.should_receive(:new).and_return(host)
    end

    it 'creates a Host by the given hostname and adds it to the list of hosts' do
      subject.add_host('test')
      subject.hosts.should == { 'test' => host }
    end

    context 'with an alias' do
      it 'lets you refer to the host by its alias' do
        subject.add_host('test', :thing)

        subject.hosts.should == { thing: host }
      end
    end
  end
end
