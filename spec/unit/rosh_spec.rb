require 'spec_helper'
require 'rosh'
require 'memfs'

describe Rosh do
  subject(:rosh_class) { Rosh }
  before { rosh_class.reset }

  describe '.add_host' do
    let(:current_host) do
      double 'Rosh::Host'
    end

    before do
      Rosh::Host.should_receive(:new).and_return(current_host)
    end

    context 'without a label' do
      it 'creates a Host by the given name and adds it to the list of hosts' do
        rosh_class.add_host('test')
        rosh_class.hosts.should == { 'test' => current_host }
      end
    end

    context 'with a label' do
      it 'lets you refer to the host by its label' do
        rosh_class.add_host('test', host_label: :thing)

        rosh_class.hosts.should == { thing: current_host }
      end
    end
  end

  describe '.hosts' do
    specify { rosh_class.hosts.should be_empty }
  end

  describe '.find_by_host_name' do
    let(:host) do
      double 'Rosh::Host', name: 'test_host'
    end

    before do
      rosh_class.instance_variable_set(:@hosts, blah: host)
    end

    context 'host_name exists' do
      it 'returns the Rosh::Host' do
        expect(rosh_class.find_by_host_name('test_host')).to eq host
      end
    end

    context 'host_name does not exist' do
      it 'returns nil' do
        expect(rosh_class.find_by_host_name('meow')).to be_nil
      end
    end
  end

  describe '.config' do
    around do |example|
      MemFs.activate!
      example.run
      MemFs.deactivate!
    end

    context '~/.roshrc exists' do
      before do
        File.open('.roshrc', 'w') { |f| f.write 'meow' }
        rosh_class.const_set(:DEFAULT_RC_FILE, '.roshrc')
      end

      it 'loads and returns the contents of the file' do
        expect(rosh_class.config).to eq 'meow'
      end
    end
  end
end
