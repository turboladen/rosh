require 'spec_helper'
require 'rosh/host/service_types/init'


describe Rosh::Host::ServiceTypes::Init do
  let(:name) { 'thing' }

  let(:shell) do
    double 'Rosh::Host::Shell'
  end

  let(:result) do
    r = double 'Rosh::CommandResult'
    r.stub(:ssh_result).and_return 'output'

    r
  end

  context 'linux' do
    subject do
      Rosh::Host::ServiceTypes::Init.new(name, shell, :linux)
    end

    describe '#info' do
      let(:info) do
        {}
      end

      context 'pid is an Array' do
        before do
          subject.should_receive(:fetch_status).
            and_return ['test state', 0, result, ['process info']]

          subject.should_receive(:build_info).
            with('test state', process_info: ['process info']).and_return info

          @r = subject.info
        end

        specify { @r.ruby_object.should eq info }
        specify { @r.exit_status.should eq 0 }
        specify { @r.ssh_result.should eq 'output' }
      end

      context 'pid is not an Array' do
        before do
          subject.should_receive(:fetch_status).
            and_return ['test state', 0, result, 123]

          subject.should_receive(:build_info).
            with('test state', pid: 123).and_return info

          @r = subject.info
        end

        specify { @r.ruby_object.should eq info }
        specify { @r.exit_status.should eq 0 }
        specify { @r.ssh_result.should eq 'output' }
      end
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
      context 'exit status is 127' do
        before do
          result.should_receive(:ruby_object).and_return 'bad service'
          result.should_receive(:exit_status).exactly(3).times.and_return 127
        end

        it 'returns a CommandResult with an UnrecognizedService exception' do
          shell.should_receive(:exec).with('/etc/init.d/thing start').
            and_return result

          subject.start
        end
      end

      context 'permission denied' do
        before do
          result.stub(:ruby_object).and_return 'permission denied'
          result.stub(:exit_status).and_return 3
          subject.should_receive(:permission_denied?).and_return true
        end

        it 'returns a CommandResult with an UnrecognizedService exception' do
          shell.should_receive(:exec).with('/etc/init.d/thing start').
            and_return result

          subject.start
        end
      end
    end

    describe '#fetch_pid' do
      context 'pids for the process name not found' do
        before do
          result.should_receive(:ruby_object).and_return []
          shell.should_receive(:ps).with(name: 'thing').and_return result
        end

        it 'returns an empty Array' do
          subject.send(:fetch_pid).should == []
        end
      end

      context 'pids for the process was found' do
        let(:process) do
          double 'Rosh::Process', pid: 123
        end

        before do
          result.should_receive(:ruby_object).and_return [process]
          shell.should_receive(:ps).with(name: 'thing').and_return result
        end

        it 'returns an Array with the pids' do
          subject.send(:fetch_pid).should == [123]
        end
      end
    end

    describe '#fetch_status' do
      before do
        shell.should_receive(:exec).with('/etc/init.d/thing status').
          and_return result
      end

      context 'exit status is 0 and a matching pid is found' do
        before do
          result.stub(:exit_status).and_return 0
          subject.stub(:fetch_pid).and_return [123]
          @r = subject.send(:fetch_status)
        end

        specify { @r[0].should eq :running }
        specify { @r[1].should eq 0 }
        specify { @r[2].should eq result }
        specify { @r[3].should eq [123] }
      end

      context 'exit status is 0 and a matching pid is not found' do
        before do
          result.stub(:exit_status).and_return 0
          subject.stub(:fetch_pid).and_return []
          @r = subject.send(:fetch_status)
        end

        specify { @r[0].should eq :stopped }
        specify { @r[1].should eq 0 }
        specify { @r[2].should eq result }
        specify { @r[3].should eq [] }
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

      context 'exit status is 127' do
        before do
          result.stub(:ruby_object).and_return ''
          result.stub(:exit_status).and_return 127
          subject.stub(:fetch_pid).and_return nil
          @r = subject.send(:fetch_status)
        end

        specify { @r[0].should be_a Rosh::UnrecognizedService  }
        specify { @r[1].should eq 127 }
        specify { @r[2].should eq result }
        specify { @r[3].should eq nil }
      end
    end
  end
end
