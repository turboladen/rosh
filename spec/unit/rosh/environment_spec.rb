require 'rosh'
require 'rosh/environment'

RSpec.describe Rosh::Environment do
  describe '#add_host' do
    let(:current_host) { instance_double 'Rosh::Host' }

    before do
      allow(Rosh::Host).to receive(:new).and_return(current_host)
    end

    context 'without a label' do
      it 'creates a Host by the given name and adds it to the list of hosts' do
        subject.add_host('test')
        expect(subject.hosts).to eq('test' => current_host)
      end
    end

    context 'with a label' do
      it 'lets you refer to the host by its label' do
        subject.add_host('test', host_label: :thing)

        expect(subject.hosts).to eq(thing: current_host)
      end
    end
  end

  describe '.find_by_host_name' do
    let(:host) { instance_double 'Rosh::Host', name: 'test_host' }
    before { subject.instance_variable_set(:@hosts, blah: host) }

    context 'host_name exists' do
      it 'returns the Rosh::Host' do
        expect(subject.find_by_host_name('test_host')).to eq host
      end
    end

    context 'host_name does not exist' do
      it 'returns nil' do
        expect(subject.find_by_host_name('meow')).to be_nil
      end
    end
  end
end
