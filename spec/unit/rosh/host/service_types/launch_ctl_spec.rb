require 'spec_helper'
require 'rosh/host/service_types/launch_ctl'


describe Rosh::Host::ServiceTypes::LaunchCTL do
  let(:name) { 'com.thing' }

  let(:shell) do
    double 'Rosh::Host::Shell'
  end

  let(:result) do
    r = double 'Rosh::CommandResult'
    r.stub(:stdout).and_return 'output'
    r.stub(:stderr)

    r
  end

  subject do
    Rosh::Host::ServiceTypes::LaunchCTL.new(name, shell)
  end

  describe '#info' do
    let(:plist) do
      <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
</plist>
      PLIST
    end

    let(:info) do
      {}
    end

    before do
      result.stub(:ruby_object).and_return plist
      subject.should_receive(:fetch_status).
        and_return ['test state', 0, result, nil]

      subject.should_receive(:build_info).with('test state', pid: nil).
        and_return info
      Plist.should_receive(:parse_xml).with(plist).
        and_return 'plist'

      @r = subject.info
    end

    specify { @r.ruby_object.should == { plist: 'plist' } }
    specify { @r.exit_status.should == 0 }
    specify { @r.stdout.should == 'output' }
  end

  describe '#status' do
    before do
      subject.should_receive(:fetch_status).
        and_return ['test state', 0, result, nil]
    end

    it 'returns a CommandResult' do
      r = subject.status
      r.should be_a Rosh::CommandResult
      r.ruby_object.should == 'test state'
      r.exit_status.should be_zero
    end
  end

  describe '#start' do
    context 'output includes "nothing found to load"' do
      before do
        result.stub(:ruby_object).and_return 'nothing found to load'
        result.should_receive(:exit_status)
      end

      it 'returns a CommandResult with an UnrecognizedService exception' do
        shell.should_receive(:exec).with('launchctl load com.thing').
          and_return result

        subject.start
      end
    end

    context 'output does not include "nothing found to load"' do
      before do
        result.stub(:ruby_object).and_return 'nothing found to load'
        result.should_receive(:exit_status)
      end

      it 'returns a CommandResult with an UnrecognizedService exception' do
        shell.should_receive(:exec).with('launchctl load com.thing').
          and_return result

        subject.start
      end
    end
  end

  describe '#fetch_pid' do
    context 'pid was not in the command output' do
      before do
        result.should_receive(:ruby_object).and_return 'no pid'
        shell.should_receive(:exec).with('launchctl list | grep com.thing').
          and_return result
      end

      it 'returns nil' do
        subject.send(:fetch_pid).should be_nil
      end
    end

    context 'pid was in the command output' do
      before do
        result.should_receive(:ruby_object).and_return '123'
        shell.should_receive(:exec).with('launchctl list | grep com.thing').
          and_return result
      end

      it 'returns the pid as a Fixnum' do
        subject.send(:fetch_pid).should == 123
      end
    end
  end

  describe '#fetch_status' do
    before do
      shell.should_receive(:exec).with('launchctl list -x com.thing').
        and_return result
    end

    context 'exit status is 0 and a matching pid is found' do
      before do
        result.stub(:exit_status).and_return 0
        subject.stub(:fetch_pid).and_return 123
        @r = subject.send(:fetch_status)
      end

      specify { @r[0].should eq :running }
      specify { @r[1].should eq 0 }
      specify { @r[2].should eq result }
      specify { @r[3].should eq 123 }
    end

    context 'exit status is 0 and a matching pid is not found' do
      before do
        result.stub(:exit_status).and_return 0
        subject.stub(:fetch_pid).and_return nil
        @r = subject.send(:fetch_status)
      end

      specify { @r[0].should eq :stopped }
      specify { @r[1].should eq 0 }
      specify { @r[2].should eq result }
      specify { @r[3].should eq nil }
    end

    context 'exit status is non-0 and output contains unknown response' do
      before do
        result.stub(:ruby_object).and_return 'launchctl list returned unknown response'
        result.stub(:exit_status).and_return 1
        subject.stub(:fetch_pid).and_return nil
        @r = subject.send(:fetch_status)
      end

      specify { @r[0].should eq :unknown }
      specify { @r[1].should eq 1 }
      specify { @r[2].should eq result }
      specify { @r[3].should eq nil }
    end

    context 'exit status is non-0 and output does not contain unknown response' do
      before do
        result.stub(:ruby_object).and_return ''
        result.stub(:exit_status).and_return 1
        subject.stub(:fetch_pid).and_return nil
        @r = subject.send(:fetch_status)
      end

      specify { @r[0].should be_a Rosh::UnrecognizedService  }
      specify { @r[1].should eq 1 }
      specify { @r[2].should eq result }
      specify { @r[3].should eq nil }
    end
  end
end
