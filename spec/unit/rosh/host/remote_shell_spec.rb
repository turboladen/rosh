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

  before do
    Net::SSH::Simple.stub(:new).and_return(ssh)
    Rosh::Host::RemoteShell.log = false
    subject.instance_variable_set(:@internal_pwd, '/home')
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

        it 'returns a CommandResult with exit status 0' do
          @r.exit_status.should eq 0
        end

        it 'returns a CommandResult with ruby object a String' do
          @r.ruby_object.should eq 'file contents'
        end

        it 'sets @last_result to its return value' do
          subject.last_result.should == @r
        end
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with('cat /etc/hosts').and_return result
          @r = subject.cat('/etc/hosts')
        end

        it 'returns a CommandResult with exit status 0' do
          @r.exit_status.should eq 0
        end

        it 'returns a CommandResult with ruby object a String' do
          @r.ruby_object.should eq 'file contents'
        end

        it 'sets @last_result to its return value' do
          subject.last_result.should == @r
        end
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

        it 'returns a CommandResult with exit status 1' do
          @r.exit_status.should eq 1
        end

        it 'returns a CommandResult with ruby object a Rosh::ErrorENOENT' do
          @r.ruby_object.should be_a Rosh::ErrorENOENT
        end

        it 'sets @last_result to its return value' do
          subject.last_result.should == @r
        end
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with('cat /etc/hosts').and_return result

          @r = subject.cat('/etc/hosts')
        end

        it 'returns a CommandResult with exit status 1' do
          @r.exit_status.should eq 1
        end

        it 'returns a CommandResult with ruby object a Rosh::ErrorENOENT' do
          @r.ruby_object.should be_a Rosh::ErrorENOENT
        end

        it 'sets @last_result to its return value' do
          subject.last_result.should == @r
        end
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

        it 'returns a CommandResult with exit status 0' do
          @r.exit_status.should eq 0
        end

        it 'returns a CommandResult with ruby object a Rosh::Host::RemoteDir' do
          @r.ruby_object.should be_a Rosh::Host::RemoteDir
        end

        it 'sets @last_result to its return value' do
          subject.last_result.should == @r
        end
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with("cd #{path} && pwd").and_return result

          @r = subject.cd('/home/path')
        end

        it 'returns a CommandResult with exit status 0' do
          @r.exit_status.should eq 0
        end

        it 'returns a CommandResult with ruby object a Rosh::Host::RemoteDir' do
          @r.ruby_object.should be_a Rosh::Host::RemoteDir
        end

        it 'sets @last_result to its return value' do
          subject.last_result.should == @r
        end
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

        it 'returns a CommandResult with exit status 1' do
          @r.exit_status.should eq 1
        end

        it 'returns a CommandResult with ruby object a Rosh::ErrorENOENT' do
          @r.ruby_object.should be_a Rosh::ErrorENOENT
        end

        it 'sets @last_result to its return value' do
          subject.last_result.should == @r
        end
      end

      context 'path is absolute' do
        it 'returns a CommandResult with exit status 1' do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with("cd #{path} && pwd").and_return result

          r = subject.cd('/home/path')
          r.exit_status.should eq 1
        end
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

      it 'returns a CommandResult with exit status 1' do
        @r.exit_status.should eq 1
      end

      it 'returns a CommandResult with ruby object Rosh::ErrorENOENT' do
        @r.ruby_object.should be_a Rosh::ErrorENOENT
      end

      it 'sets @last_result to its return value' do
        subject.last_result.should == @r
      end
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

      it 'returns a CommandResult with exit status 1' do
        @r.exit_status.should eq 1
      end

      it 'returns a CommandResult with ruby object Rosh::ErrorEISDIR' do
        @r.ruby_object.should be_a Rosh::ErrorEISDIR
      end

      it 'sets @last_result to its return value' do
        subject.last_result.should == @r
      end
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

      it 'returns a CommandResult with exit status 0' do
        @r.exit_status.should eq 0
      end

      it 'returns a CommandResult with ruby object the CommandResult' do
        @r.ruby_object.should == true
      end

      it 'sets @last_result to its return value' do
        subject.last_result.should == @r
      end
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

      let(:internal_pwd) do
        double 'Rosh::RemoteDir', to_path: '/home'
      end

      before do
        subject.instance_variable_set(:@internal_pwd, internal_pwd)
        subject.should_receive(:run).with('cd /home && blah').and_return result
        @r = subject.exec('blah')
      end

      it 'returns a CommandResult with exit status 1' do
        @r.exit_status.should == 1
      end

      it 'returns a CommandResult with ruby object the output of the failed command' do
        @r.ruby_object.should == 'command not found'
      end

      it 'sets @last_result to its return value' do
        subject.last_result.should == @r
      end
    end

    context 'valid command' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:ruby_object).and_return 'some output'

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

      it 'returns a CommandResult with exit status 0' do
        @r.exit_status.should == 0
      end

      it 'returns a CommandResult with ruby object the output of the command' do
        @r.ruby_object.should == 'some output'
      end

      it 'sets @last_result to its return value' do
        subject.last_result.should == @r
      end
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

        it 'returns a CommandResult with exit status 0' do
          @r.exit_status.should eq 0
        end

        it 'returns a CommandResult with ruby object an Array of RemoteFileSystemObjects' do
          @r.ruby_object.should == [file_system_object]
        end

        it 'sets @last_result to its return value' do
          subject.last_result.should == @r
        end
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with("ls #{path}").and_return result

          @r = subject.ls('/home/path')
        end

        it 'returns a CommandResult with exit status 0' do
          @r.exit_status.should eq 0
        end

        it 'returns a CommandResult with ruby object an Array of RemoteFileSystemObjects' do
          @r.ruby_object.should == [file_system_object]
        end

        it 'sets @last_result to its return value' do
          subject.last_result.should == @r
        end
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

        it 'returns a CommandResult with exit status 1' do
          @r.exit_status.should eq 1
        end

        it 'returns a CommandResult with ruby object a Rosh::ErrorENOENT' do
          @r.ruby_object.should be_a Rosh::ErrorENOENT
        end

        it 'sets @last_result to its return value' do
          subject.last_result.should == @r
        end
      end

      context 'path is absolute' do
        it 'returns a CommandResult with exit status 1' do
          subject.should_receive(:preprocess_path).with(path).and_return path
          subject.should_receive(:run).with("ls #{path}").and_return result

          r = subject.ls('/home/path')
          r.exit_status.should eq 1
        end
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

      it 'returns a CommandResult with exit status 0' do
        @r.exit_status.should be_zero
      end

      it 'returns a CommandResult with ruby object an Array of Rosh::RemoteProcTable' do
        @r.ruby_object.should be_a Array
        @r.ruby_object.size.should == 2

        @r.ruby_object.first.should be_a Rosh::Host::RemoteProcTable
        @r.ruby_object.first.user.should == 'root'
        @r.ruby_object.first.pid.should == 1
        @r.ruby_object.first.cpu.should == 0.0
        @r.ruby_object.first.mem.should == 0.2
        @r.ruby_object.first.vsz.should == 2036
        @r.ruby_object.first.rss.should == 716
        @r.ruby_object.first.tty.should == '?'
        @r.ruby_object.first.stat.should == 'Ss'
        @r.ruby_object.first.start.should == Time.parse('18:45')
        @r.ruby_object.first.time.should == '0:01'
        @r.ruby_object.first.command.should == 'init [2]'
      end

      it 'sets @last_result to its return value' do
        subject.last_result.should == @r
      end
    end

    context 'valid name given' do
      before { @r = subject.ps('init') }

      it 'returns a CommandResult with exit status 0' do
        @r.exit_status.should be_zero
      end

      it 'returns a CommandResult with ruby object an Array of Rosh::RemoteProcTable' do
        @r.ruby_object.should be_a Array
        @r.ruby_object.size.should == 1

        @r.ruby_object.first.should be_a Rosh::Host::RemoteProcTable
        @r.ruby_object.first.user.should == 'root'
        @r.ruby_object.first.pid.should == 1
        @r.ruby_object.first.cpu.should == 0.0
        @r.ruby_object.first.mem.should == 0.2
        @r.ruby_object.first.vsz.should == 2036
        @r.ruby_object.first.rss.should == 716
        @r.ruby_object.first.tty.should == '?'
        @r.ruby_object.first.stat.should == 'Ss'
        @r.ruby_object.first.start.should == Time.parse('18:45')
        @r.ruby_object.first.time.should == '0:01'
        @r.ruby_object.first.command.should == 'init [2]'
      end

      it 'sets @last_result to its return value' do
        subject.last_result.should == @r
      end
    end

    context 'non-existant process name given' do
      before { @r = subject.ps('sdfsdfdsfs') }

      it 'returns a CommandResult with exit status 0' do
        @r.exit_status.should be_zero
      end

      it 'returns a CommandResult with ruby object an empty Array' do
        @r.ruby_object.should be_a Array
        @r.ruby_object.size.should == 0
      end

      it 'sets @last_result to its return value' do
        subject.last_result.should == @r
      end
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
        subject.instance_variable_set(:@internal_pwd, nil)
      end

      it 'runs "pwd" over ssh' do
        subject.should_receive(:run).with('pwd').and_return result

        result = subject.pwd
        result.should be_a Rosh::CommandResult
        result.ruby_object.should be_a Rosh::Host::RemoteDir
        result.exit_status.should == 0
        subject.last_result.should == result
      end
    end

    context '@internal_pwd is set' do
      it 'does not run "pwd" over ssh, but returns @internal_pwd' do
        subject.should_not_receive(:run).with('pwd')

        result = subject.pwd
        result.should be_a Rosh::CommandResult
        result.ruby_object.should == '/home'
        result.exit_status.should == 0
        subject.last_result.should == result
      end
    end
  end
end
