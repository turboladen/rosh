require 'spec_helper'
require 'rosh/host/remote_shell'


describe Rosh::Host::RemoteShell do
  let(:ssh) do
    double 'Net::SSH::Simple'
  end

  let(:hostname) { 'testhost' }
  let(:outcome) { double 'Rosh::CommandResult' }
  let(:ssh_output) do
    o = double 'SSH command output'
    o.stub(:exit_code).and_return 0

    o
  end

  subject do
    Rosh::Host::RemoteShell.new(hostname)
  end

  let(:internal_pwd) do
    i = double 'Rosh::Host::RemoteDir'
    i.stub(:to_path).and_return '/home'

    i
  end

  before do
    Net::SSH::Simple.stub(:new).and_return(ssh)
    Rosh::Host::RemoteShell.log = false
    subject.instance_variable_set(:@internal_pwd, internal_pwd)
  end

  after do
    Net::SSH::Simple.unstub(:new)
  end

  describe '#initialize' do
    context 'no options passed in' do
      its(:options) { should eq(user: Etc.getlogin, timeout: 1800) }
    end

    context ':user option passed in' do
      subject { Rosh::Host::RemoteShell.new('test', user: 'bobo') }
      its(:options) { should eq(user: 'bobo', timeout: 1800) }
    end

    context ':timeout option passed in' do
      subject { Rosh::Host::RemoteShell.new('test', timeout: 1) }
      its(:options) { should eq(user: Etc.getlogin, timeout: 1) }
    end

    context ':meow option passed in' do
      subject { Rosh::Host::RemoteShell.new('test', meow: 'cat') }
      its(:options) { should eq(user: Etc.getlogin, timeout: 1800, meow: 'cat') }
    end
  end

  describe '#set' do
    context 'no params' do
      it 'does not change @options' do
        expect { subject.set }.to_not change { subject.options }
      end
    end

    context 'one key/value pair' do
      it 'updates @options' do
        subject.set thing: 'one'
        subject.options.should include(thing: 'one')
      end
    end
  end

  describe '#unset' do
    context 'no params' do
      it 'does not change @options' do
        expect { subject.unset }.to_not change { subject.options }
      end
    end

    context 'key that exists' do
      it 'removes that option' do
        subject.options.should include(timeout: 1800)
        subject.unset :timeout
        subject.options.should_not include(timeout: 1800)
      end
    end

    context 'key that does not exist' do
      it 'does not change options' do
        expect { subject.unset :asdfasdfas }.to_not change { subject.options }
      end
    end
  end

  describe '#run' do
    context 'with no options' do
      it 'runs the command and returns an ActionResult object' do
        expected_options = {
          user: Etc.getlogin,
          timeout: 1800
        }

        ssh.should_receive(:ssh).
          with(hostname, 'test command', expected_options).
          and_return ssh_output
        Rosh::CommandResult.should_receive(:new).
          with(nil, 0,ssh_output).and_return outcome

        o = subject.run 'test command'
        o.should == outcome
      end
    end

    context 'with options' do
      let(:options) do
        { one: 'one', two: 'two' }
      end

      it 'merges @options and runs the command' do
        expected_options = {
          user: Etc.getlogin,
          timeout: 1800,
          one: 'one',
          two: 'two'
        }

        ssh.should_receive(:ssh).
          with(hostname, 'test command', expected_options).and_return ssh_output
        Rosh::CommandResult.should_receive(:new).
          with(nil, 0, ssh_output).and_return outcome

        subject.run 'test command', options
      end
    end
  end

  describe '#upload' do
    context 'with no options' do
      it 'runs the command and returns an ActionResult object' do
        expected_options = {
          user: Etc.getlogin,
          timeout: 1800
        }

        ssh.should_receive(:scp_ul).
          with(hostname, 'test file', '/destination', expected_options).
          and_return ssh_output
        Rosh::CommandResult.should_receive(:new).
          with(nil, 0, ssh_output).and_return outcome

        o = subject.upload 'test file', '/destination'
        o.should == outcome
      end
    end

    context 'with options' do
      let(:options) do
        { one: 'one', two: 'two' }
      end

      it 'merges @options and runs the command' do
        expected_options = {
          user: Etc.getlogin,
          timeout: 1800,
          one: 'one',
          two: 'two'
        }

        ssh.should_receive(:scp_ul).
          with(hostname, 'test file', '/destination', expected_options).
          and_return ssh_output
        Rosh::CommandResult.should_receive(:new).
          with(nil, 0, ssh_output).and_return outcome

        subject.upload 'test file', '/destination', options
      end
    end
  end

  describe '#cat' do
    let(:path) { '/etc/hosts' }

    context 'path exists' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:ruby_object).and_return 'file contents'
        r.stub_chain(:ssh_result, :stderr).and_return ''

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
        r.stub(:exit_status).and_return 1
        r.stub_chain(:ssh_result, :stderr).and_return 'No such file or directory'

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

  describe '#cd' do
    let(:path) { '/home/path' }

    context 'path exists' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:ruby_object).and_return path
        r.stub(:ssh_result)

        r
      end

      context 'path is relative' do
        before do
          subject.should_receive(:preprocess_path).with('path').and_return path
          subject.should_receive(:run).with("cd #{path} && pwd").and_return result
          @r = subject.cd('path')
        end

        specify { @r.should be_true}
        specify { subject.last_exit_status.should eq 0 }
        specify { subject.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with("cd #{path} && pwd").and_return result

          @r = subject.cd('/home/path')
        end

        specify { @r.should be_true }
        specify { subject.last_exit_status.should eq 0 }
        specify { subject.last_result.should eq @r }
      end
    end

    context 'path does not exist' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 1
        r.stub_chain(:ssh_result, :stderr).and_return 'No such file or directory'

        r
      end

      context 'path is relative' do
        before do
          subject.should_receive(:preprocess_path).with('path').and_return path
          subject.should_receive(:run).with("cd #{path} && pwd").and_return result
          @r = subject.cd('path')
        end

        specify { @r.should be_a Rosh::ErrorENOENT }
        specify { subject.last_exit_status.should eq 1 }
        specify { subject.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with("cd #{path} && pwd").and_return result

          @r = subject.cd('/home/path')
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
        r.stub_chain(:ssh_result, :stderr).and_return 'No such file or directory'

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
        r.stub_chain(:ssh_result, :stderr).and_return 'omitting directory'

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
        r.stub_chain(:ssh_result, :stderr).and_return ''

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

  describe '#exec' do
    context 'invalid command' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 1
        r.stub_chain(:ssh_result, :stdout).and_return ''
        r.stub_chain(:ssh_result, :stderr).and_return 'command not found'

        r
      end

      before do
        subject.should_receive(:run).with('cd /home && blah').and_return result
        @r = subject.exec('blah')
      end

      specify { @r.should eq 'command not found' }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'valid command' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:ruby_object).and_return 'some output'
        r.stub(:ssh_result).and_return 'some output'

        r
      end

      let(:internal_pwd) do
        double 'Rosh::RemoteDir', to_path: '/home'
      end

      before do
        subject.instance_variable_set(:@internal_pwd, internal_pwd)
        subject.should_receive(:run).with('cd /home && blah').and_return result
        @r = subject.exec('blah')
      end

      specify { @r.should eq 'some output' }
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
        r.stub_chain(:ssh_result, :stderr).and_return ''

        r
      end

      let(:file_system_object) do
        double 'Rosh::Host::RemoteFileSystemObject'
      end

      before do
        Rosh::Host::RemoteFileSystemObject.should_receive(:create).
          and_return file_system_object
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
        r.stub_chain(:ssh_result, :stderr).and_return 'No such file or directory'

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
      r.stub_chain(:ssh_result, :stdout).and_return ps_list

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

  describe '#pwd' do
    let(:result) do
      r = double 'Rosh::CommandResult'
      r.stub(:ruby_object).and_return 'some path'

      r
    end

    context '@internal_pwd is not set' do
      before do
        result.stub(:ssh_result)
        subject.instance_variable_set(:@internal_pwd, nil)
        subject.should_receive(:run).with('pwd').and_return result

        @r = subject.pwd
      end

      specify { @r.should be_a Rosh::Host::RemoteDir }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end

    context '@internal_pwd is set' do
      before do
        subject.should_not_receive(:run).with('pwd')

        @r = subject.pwd
      end

      specify { @r.should eq internal_pwd }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end
  end
end
