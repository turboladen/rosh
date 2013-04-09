require 'spec_helper'
require 'rosh/host/service'


describe Rosh::Host::Service do
  let(:name) { 'com.thing' }

  let(:shell) do
    double 'Rosh::Host::Shell'
  end

  let(:host) do
    h = double 'Rosh::Host'
    h.stub(:shell).and_return shell

    h
  end

  subject do
    Rosh::Host::Service.new(name, host)
  end

  describe '#status' do
    context 'OSX' do
      let(:plist) do
        <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
</plist>
        PLIST
      end

      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:ruby_object).and_return plist
        r.stub(:exit_status).and_return 0
        r.stub(:ssh_result).and_return 'output'

        r
      end

      before do
        host.stub(:operating_system).and_return :darwin
        shell.should_receive(:exec).with('launchctl list -x com.thing').
          and_return result
      end

      it 'uses Plist to parse `launchctl list` output to a Hash' do
        Plist.should_receive(:parse_xml).with(plist)
        subject.status
      end
    end
  end
end
