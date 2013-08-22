require 'spec_helper'
require 'rosh'

describe Rosh do
  subject { Rosh }
  before { subject.reset }

  describe '.add_host' do
    let(:current_host) do
      double 'Rosh::Host'
    end

    before do
      Rosh::Host.should_receive(:new).and_return(current_host)
    end

    context 'without a label' do
      it 'creates a Host by the given name and adds it to the list of hosts' do
        subject.add_host('test')
        subject.hosts.should == { 'test' => current_host }
      end
    end

    context 'with a label' do
      it 'lets you refer to the host by its label' do
        subject.add_host('test', host_label: :thing)

        subject.hosts.should == { thing: current_host }
      end
    end
  end

  describe '.hosts' do
    specify { subject.hosts.should be_empty }
  end
end
