require 'spec_helper'
require 'rosh/host/shells/remote'


describe Rosh::Host::WrapperMethods::Remote do
  subject { Rosh::Host::Shells::Remote.new('testhost') }

  let(:ssh) do
    double 'Net::SSH::Connection', close: true, :closed? => true
  end

  let(:internal_pwd) do
    i = double 'Rosh::Host::FileSystemObjects::RemoteDir'
    i.stub(:to_path).and_return '/home'

    i
  end

  before do
    Net::SSH.stub(:start).and_return(ssh)
    Rosh::Host::Shells::Remote.log = false
    subject.instance_variable_set(:@internal_pwd, internal_pwd)
  end

  after do
    Net::SSH.unstub(:start)
  end

  describe '#cat' do
    let(:path) { '/etc/hosts' }

    context 'path exists' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:ruby_object).and_return 'file contents'
        r.stub(:stdout).and_return ''
        r.stub(:stderr).and_return ''

        r
      end

      context 'path is relative' do
        before do
          subject.should_receive(:preprocess_path).with('hosts').and_return path
          subject.should_receive(:run).with('cat /etc/hosts').and_return result
          @r = subject.cat('hosts')
        end

        specify { @r.should eq 'file contents' }
        specify { subject.last_exit_status.should eq 0 }
        specify { subject.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with('cat /etc/hosts').and_return result
          @r = subject.cat('/etc/hosts')
        end

        specify { @r.should eq 'file contents' }
        specify { subject.last_exit_status.should eq 0 }
        specify { subject.last_result.should eq @r }
      end
    end

    context 'path does not exist' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        allow(r).to receive(:exit_status) { 1 }
        allow(r).to receive(:stderr) { 'No such file or directory' }
        allow(r).to receive(:stdout) { 'stuff' }

        r
      end

      context 'path is relative' do
        before do
          subject.should_receive(:preprocess_path).with('hosts').and_return path
          subject.should_receive(:run).with('cat /etc/hosts').and_return result

          @r = subject.cat('hosts')
        end

        specify { @r.should be_a Rosh::ErrorENOENT }
        specify { subject.last_exit_status.should eq 1 }
        specify { subject.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with('cat /etc/hosts').and_return result

          @r = subject.cat('/etc/hosts')
        end

        specify { @r.should be_a Rosh::ErrorENOENT }
        specify { subject.last_exit_status.should eq 1 }
        specify { subject.last_result.should eq @r }
      end
    end
  end

  describe '#cp' do
    let(:source) { '/home/path' }

    context 'source does not exist' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 1
        r.stub(:stderr).and_return 'No such file or directory'
        r.stub(:stdout)

        r
      end

      before do
        subject.should_receive(:preprocess_path).with(source).and_return source
        subject.should_receive(:preprocess_path).with('dest').and_return 'dest'
        subject.should_receive(:run).with("cp #{source} dest").and_return result
        @r = subject.cp(source, 'dest')
      end

      specify { @r.should be_a Rosh::ErrorENOENT }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'source is a directory' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 1
        r.stub(:stderr).and_return 'omitting directory'
        r.stub(:stdout)

        r
      end

      before do
        subject.should_receive(:preprocess_path).with(source).and_return source
        subject.should_receive(:preprocess_path).with('dest').and_return 'dest'
        subject.should_receive(:run).with("cp #{source} dest").and_return result
        @r = subject.cp(source, 'dest')
      end

      specify { @r.should be_a Rosh::ErrorEISDIR }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'destination exists' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:stderr).and_return ''
        r.stub(:stdout)

        r
      end

      before do
        subject.should_receive(:preprocess_path).with(source).and_return source
        subject.should_receive(:preprocess_path).with('dest').and_return 'dest'
        subject.should_receive(:run).with("cp #{source} dest").and_return result
        @r = subject.cp(source, 'dest')
      end

      specify { @r.should be_true }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end
  end

  describe '#ls' do
    let(:path) { '/home/path' }

    context 'path exists' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:ruby_object).and_return path
        r.stub(:stderr).and_return ''
        r.stub(:stdout)

        r
      end

      let(:file_system_object) do
        double 'Rosh::Host::FileSystemObjects::RemoteBase'
      end

      before do
        Rosh::FileSystem.should_receive(:create).and_return file_system_object
      end

      context 'path is relative' do
        before do
          subject.should_receive(:preprocess_path).with('path').and_return path
          subject.should_receive(:run).with("ls #{path}").and_return result
          @r = subject.ls('path')
        end

        specify { @r.should eq [file_system_object] }
        specify { subject.last_exit_status.should eq 0 }
        specify { subject.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with("ls #{path}").and_return result

          @r = subject.ls('/home/path')
        end

        specify { @r.should eq [file_system_object] }
        specify { subject.last_exit_status.should eq 0 }
        specify { subject.last_result.should eq @r }
      end
    end

    context 'path does not exist' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 1
        r.stub(:stderr).and_return 'No such file or directory'
        r.stub(:stdout)

        r
      end

      context 'path is relative' do
        before do
          subject.should_receive(:preprocess_path).with('path').and_return path
          subject.should_receive(:run).with("ls #{path}").and_return result
          @r = subject.ls('path')
        end

        specify { @r.should be_a Rosh::ErrorENOENT }
        specify { subject.last_exit_status.should eq 1 }
        specify { subject.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with("ls #{path}").and_return result

          @r = subject.ls('/home/path')
        end

        specify { @r.should be_a Rosh::ErrorENOENT }
        specify { subject.last_exit_status.should eq 1 }
        specify { subject.last_result.should eq @r }
      end
    end
  end

  describe '#ps' do
    let(:ps_list) do
      <<-PS
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.2   2036   716 ?        Ss   18:45   0:01 init [2]
bobo         2  0.1  1.2    712    16 ?        S    18:46   0:01 /bin/bash
      PS
    end

    let(:result) do
      r = double 'Rosh::CommandResult'
      r.stub(:stdout).and_return ps_list
      r.stub(:stderr)

      r
    end

    before do
      subject.should_receive(:run).with('ps auxe').and_return result
    end

    context 'no name given' do
      before { @r = subject.ps }

      it 'returns a CommandResult with ruby object an Array of Rosh::RemoteProcTable' do
        @r.should be_a Array
        @r.size.should == 2

        @r.first.should be_a Rosh::Host::RemoteProcTable
        @r.first.user.should == 'root'
        @r.first.pid.should == 1
        @r.first.cpu.should == 0.0
        @r.first.mem.should == 0.2
        @r.first.vsz.should == 2036
        @r.first.rss.should == 716
        @r.first.tty.should == '?'
        @r.first.stat.should == 'Ss'
        @r.first.start.should == Time.parse('18:45')
        @r.first.time.should == '0:01'
        @r.first.command.should == 'init [2]'
      end

      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end

    context 'valid name given' do
      before { @r = subject.ps(name: 'init') }

      it 'returns a CommandResult with ruby object an Array of Rosh::RemoteProcTable' do
        @r.should be_a Array
        @r.size.should == 1

        @r.first.should be_a Rosh::Host::RemoteProcTable
        @r.first.user.should == 'root'
        @r.first.pid.should == 1
        @r.first.cpu.should == 0.0
        @r.first.mem.should == 0.2
        @r.first.vsz.should == 2036
        @r.first.rss.should == 716
        @r.first.tty.should == '?'
        @r.first.stat.should == 'Ss'
        @r.first.start.should == Time.parse('18:45')
        @r.first.time.should == '0:01'
        @r.first.command.should == 'init [2]'
      end

      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end

    context 'non-existant process name given' do
      before { @r = subject.ps(name: 'sdfsdfdsfs') }

      specify { @r.should eq [] }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end
  end
end
