require 'spec_helper'
require 'rosh/host/service_types/launch_ctl'


describe Rosh::Host::ServiceTypes::LaunchCTL do
  let(:name) { 'com.thing' }
  let(:shell) { double 'Rosh::Host::Shell' }

  let(:result) do
    r = double 'Rosh::CommandResult'
    r.stub(:stdout).and_return 'output'
    r.stub(:stderr)

    r
  end

  subject { Rosh::Host::ServiceTypes::LaunchCTL.new(name, shell) }

  describe '#info' do
    let(:info) { {} }

    let(:plist) do
      <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
</plist>
      PLIST
    end

    before do
      expect(subject).to receive(:fetch_status) { ['test state', plist, nil] }
      expect(subject).to receive(:build_info).with('test state', pid: nil).
        and_return info
      expect(Plist).to receive(:parse_xml).with(plist) { 'plist' }
    end

    specify { subject.info.should == { plist: 'plist' } }
  end

  describe '#status' do
    before do
      expect(subject).to receive(:fetch_status) { ['test state', '', nil] }
    end

    it 'returns a the state' do
      expect(subject.status).to eq 'test state'
    end
  end

  describe '#start' do
    pending
  end

  describe '#start!' do
    context 'output includes "nothing found to load"' do
      let(:result) { 'nothing found to load' }

      it 'raises an UnrecognizedService exception' do
        expect(shell).to receive(:exec).with('launchctl load com.thing').
          and_return result

        expect { subject.start! }.to raise_error Rosh::UnrecognizedService
      end
    end

    context 'output does not include "nothing found to load"' do
      let(:result) { 'stuff' }

      it 'returns nil' do
        expect(shell).to receive(:exec).with('launchctl load com.thing').
          and_return result

        expect(subject.start!).to be_nil
      end
    end
  end

  describe '#fetch_pid' do
    context 'pid was not in the command output' do
      before do
        shell.should_receive(:exec).with('launchctl list | grep com.thing').
          and_return 'no pid'
      end

      it 'returns nil' do
        subject.send(:fetch_pid).should be_nil
      end
    end

    context 'pid was in the command output' do
      before do
        shell.should_receive(:exec).with('launchctl list | grep com.thing').
          and_return '123'
      end

      it 'returns the pid as a Fixnum' do
        subject.send(:fetch_pid).should == 123
      end
    end
  end

  describe '#fetch_status' do
    let(:result) { 'the result' }

    before do
      shell.should_receive(:exec).with('launchctl list -x com.thing').
        and_return result
    end

    context 'exit status is 0 and a matching pid is found' do
      before do
        allow(shell).to receive(:last_exit_status) { 0 }
        allow(subject).to receive(:fetch_pid).and_return 123
      end

      specify do
        expect(subject.send(:fetch_status)).to eq [:running, 'the result', 123]
      end
    end

    context 'exit status is 0 and a matching pid is not found' do
      before do
        allow(shell).to receive(:last_exit_status) { 0 }
        allow(subject).to receive(:fetch_pid).and_return nil
      end

      specify do
        expect(subject.send(:fetch_status)).to eq [:stopped, 'the result', nil]
      end
    end

    context 'exit status is non-0 and output contains unknown response' do
      let(:result) { 'launchctl list returned unknown response' }

      before do
        allow(shell).to receive(:last_exit_status).and_return 1
        allow(subject).to receive(:fetch_pid)
      end

      specify do
        expect(subject.send(:fetch_status)).to eq [:unknown, result, nil]
      end
    end

    context 'exit status is non-0 and output does not contain unknown response' do
      let(:result) { '' }

      before do
        allow(shell).to receive(:last_exit_status).and_return 1
        allow(subject).to receive(:fetch_pid)
      end

      specify do
        expect(subject.send(:fetch_status)).
          to eq [:unrecognized_service, result, nil]
      end
    end
  end
end
