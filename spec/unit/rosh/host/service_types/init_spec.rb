require 'spec_helper'
require 'rosh/host/service_types/init'


describe Rosh::Host::ServiceTypes::Init do
  let(:name) { 'thing' }
  let(:shell) { double 'Rosh::Host::Shell' }

  let(:result) do
    r = double 'Rosh::CommandResult'
    r.stub(:stdout).and_return 'output'
    r.stub(:stderr)

    r
  end

  context 'linux' do
    subject { Rosh::Host::ServiceTypes::Init.new(name, shell, :linux) }

    describe '#info' do
      let(:info) { double 'service info' }

      context 'pid is an Array' do
        before do
          expect(subject).to receive(:fetch_status) { 'test state' }
          expect(subject).to receive(:fetch_pid) { ['process info'] }
          expect(subject).to receive(:build_info).
            with('test state', process_info: ['process info']).and_return info
        end

        specify { expect(subject.info).to eq info }
      end

      context 'pid is not an Array' do
        before do
          expect(subject).to receive(:fetch_status) { 'test state' }
          expect(subject).to receive(:fetch_pid) { 123 }
          expect(subject).to receive(:build_info).
            with('test state', pid: 123).and_return info
        end

        specify { expect(subject.info).to eq info }
      end
    end

    describe '#start' do
      it 'runs the start command' do
        allow(shell).to receive(:last_exit_status) { 0 }
        expect(shell).to receive(:exec).with '/etc/init.d/thing start'
        subject.start
      end

      context 'successful command' do
        before do
          allow(shell).to receive(:last_exit_status) { 0 }
          allow(shell).to receive(:exec)
        end

        specify { subject.start.should be_true }
      end

      context 'unsuccessful command' do
        before do
          allow(shell).to receive(:last_exit_status) { 1 }
          allow(shell).to receive(:exec)
        end

        specify { subject.start.should be_false }
      end
    end

    describe '#start!' do
      let(:result) { double 'result' }

      context 'exit status is 127' do
        before { allow(shell).to receive(:last_exit_status) { 127 } }

        it 'raises an UnrecognizedService exception' do
          expect(shell).to receive(:exec).with('/etc/init.d/thing start')

          expect { subject.start! }.to raise_error Rosh::UnrecognizedService
        end
      end

      context 'permission denied' do
        before do
          allow(shell).to receive(:last_exit_status) { 3 }
          expect(subject).to receive(:permission_denied?).and_return true
        end

        it 'raises a PermissionDenied exception' do
          expect(shell).to receive(:exec).with('/etc/init.d/thing start')

          expect { subject.start! }.to raise_error Rosh::PermissionDenied
        end
      end
    end

    describe '#fetch_pid' do
      context 'pids for the process name not found' do
        before { expect(shell).to receive(:ps).with(name: 'thing') { [] } }

        it 'returns an empty Array' do
          subject.send(:fetch_pid).should == []
        end
      end

      context 'pids for the process was found' do
        let(:process) { double 'Rosh::Process', pid: 123 }

        before do
          shell.should_receive(:ps).with(name: 'thing').and_return [process]
        end

        it 'returns an Array with the pids' do
          subject.send(:fetch_pid).should == [123]
        end
      end
    end

    describe '#status' do
      before do
        expect(shell).to receive(:exec).with('/etc/init.d/thing status').
          and_return result
      end

      context 'exit status is 0 and a matching pid is found' do
        before do
          allow(shell).to receive(:last_exit_status) { 0 }
          subject.stub(:fetch_pid).and_return [123]
        end

        specify { expect(subject.status).to eq :running }
      end

      context 'exit status is 0 and a matching pid is not found' do
        before do
          allow(shell).to receive(:last_exit_status) { 0 }
          subject.stub(:fetch_pid).and_return []
        end

        specify { expect(subject.status).to eq :stopped }
      end

      context 'exit status is non-0 and output contains unknown response' do
        before do
          allow(shell).to receive(:last_exit_status) { 1 }
        end

        specify { expect(subject.status).to eq :unknown }
      end

      context 'exit status is 127' do
        before do
          allow(shell).to receive(:last_exit_status) { 127 }
        end

        specify { expect(subject.status).to eq :unrecognized_service }
      end
    end
  end
end
