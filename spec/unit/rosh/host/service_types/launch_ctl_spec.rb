require 'spec_helper'
require 'rosh/host/service_types/launch_ctl'


describe Rosh::Host::ServiceTypes::LaunchCTL do
  let(:name) { 'com.thing' }

  let(:shell) do
    double 'Rosh::Host::Shell'
  end

  subject do
    Rosh::Host::ServiceTypes::LaunchCTL.new(name, shell)
  end

  describe '#info' do
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
        r.stub(:ssh_result).and_return 'output'

        r
      end

      let(:info) do
        {}
      end

      before do
        subject.should_receive(:fetch_status).
          and_return ['test state', 0, result, nil]

        subject.should_receive(:build_info).with('test state', pid: nil).
          and_return info
      end

      it 'uses Plist to parse `launchctl list` output to a Hash' do
        Plist.should_receive(:parse_xml).with(plist).
          and_return 'plist'

        r = subject.info
        r.ruby_object.should == { plist: 'plist' }
        r.exit_status.should == 0
        r.ssh_result.should == 'output'
      end
    end
  end

  describe '#fetch_pid' do
    pending
  end

  describe '#fetch_status' do
    let(:result) do
      r = double 'Rosh::CommandResult'
      r.stub(:ruby_object).and_return plist
      r.stub(:exit_status).and_return 0
      r.stub(:ssh_result).and_return 'output'

      r
    end

    before do
      shell.should_receive(:exec).with('launchctl list -x com.thing').
        and_return result
    end

    pending
  end
end
