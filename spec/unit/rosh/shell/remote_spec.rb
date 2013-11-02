require 'spec_helper'
require 'rosh/shell/adapters/remote'


describe Rosh::Shell::Adapters::Remote do
  let(:ssh) do
    double 'Net::SSH::Connection', close: true, :closed? => true
  end

  let(:host_name) { 'testhost' }
  let(:outcome) { double 'Rosh::CommandResult' }
  let(:internal_pwd) { '/home' }

  let(:ssh_output) do
    o = double 'SSHResult'
    o.stub(:exit_status).and_return 0
    o.stub(:stdout).and_return ''
    o.stub(:stderr).and_return ''

    o
  end

  subject(:shell) do
    Object.new.extend(described_class)
  end

  before do
    Net::SSH.stub(:start).and_return(ssh)
    #Rosh::Host::Shells::Remote.log = false
    subject.instance_variable_set(:@internal_pwd, internal_pwd)
    allow(subject).to receive(:log)
  end

  after do
    Net::SSH.unstub(:start)
  end

  describe '#upload' do
    context 'all goes well' do
      it 'runs the command and returns an CommandResult object' do
        subject.should_receive(:scp).with('test file', '/destination')
        Rosh::Shell::CommandResult.should_receive(:new).
          with(nil, 0).and_return outcome

        o = subject.upload 'test file', '/destination'
        o.should == outcome
      end
    end

    context 'a Net::SSH::AuthenticationFailed error occurs' do
      before do
        subject.should_receive(:scp).and_raise Net::SSH::AuthenticationFailed
      end

      context 'successful password is entered' do
        it 'carries on with the scp' do
          subject.should_receive(:prompt).once.and_return 'test password'
          subject.should_receive(:scp).with('test file', '/destination')

          Rosh::Shell::CommandResult.should_receive(:new).with(nil, 0).and_return outcome

          subject.upload('test file', '/destination')
          subject.ssh_options[:password].should == 'test password'
        end
      end

      context 'unsuccessful password is entered' do
        before do
          subject.should_receive(:scp).and_raise Net::SSH::AuthenticationFailed
        end

        it 'returns a CommandResult with the exception' do
          subject.should_receive(:prompt).once.and_return 'test password'
          subject.should_receive(:bad_info).with 'Authentication failed.'

          Rosh::Shell::CommandResult.should_receive(:new) do |ruby_obj, exit_status|
            ruby_obj.should be_a Net::SSH::AuthenticationFailed
            exit_status.should eq 1
          end

          subject.upload('test file', '/destination')
        end
      end
    end

    context 'doing sudo upload' do
      before do
        subject.instance_variable_set(:@sudo, true)
      end

      it 'calls #upload with a tmp path' do
        subject.should_receive(:upload).with('tmp file', '/destination').
          and_call_original
        subject.should_receive(:upload).with('tmp file', '/tmp/rosh_upload',
          true, '/destination')

        subject.upload('tmp file', '/destination')
      end

      it 'uploads and copies the remote file to the originally request destination' do
        subject.should_receive(:upload).with('tmp file', '/destination').
          and_call_original
        subject.should_receive(:upload).with('tmp file', '/tmp/rosh_upload',
          true, '/destination').and_call_original
        subject.should_receive(:scp).with('tmp file', '/tmp/rosh_upload')
        #subject.should_receive(:exec).
        #  with('cp /tmp/rosh_upload /destination && rm /tmp/rosh_upload')

        subject.upload('tmp file', '/destination')
      end
    end
  end

  describe '#cat' do
    let(:path) { '/etc/hosts' }

    context 'path exists' do
      let(:result) do
        r = double 'Rosh::Shell::CommandResult'
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
        r = double 'Rosh::Shell::CommandResult'
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

  describe '#cd' do
    let(:path) { '/home/path' }

    context 'path exists' do
      let(:result) do
        r = double 'Rosh::Shell::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:ruby_object).and_return path
        r.stub(:stdout)
        r.stub(:stderr)

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
        r = double 'Rosh::Shell::CommandResult'
        r.stub(:exit_status).and_return 1
        r.stub(:stderr).and_return 'No such file or directory'
        r.stub(:stdout)

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

  describe '#exec' do
    context 'invalid command' do
      let(:result) do
        r = double 'Rosh::Shell::CommandResult'
        r.stub(:exit_status).and_return 1
        r.stub(:stdout).and_return ''
        r.stub(:stderr).and_return 'command not found'

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
        r = double 'Rosh::Shell::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:ruby_object).and_return 'some output'
        r.stub(:stdout).and_return 'some output'

        r
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

  describe '#pwd' do
    let(:dir) do
      r = double 'Rosh::Host::FileSystemObjects::RemoteDir'
      r.stub(:to_path).and_return 'some path'

      r
    end

    before { expect(subject).to receive(:_pwd) { dir } }
    specify { expect(subject.pwd).to eq dir }
  end

  describe '#run' do
    it 'runs the command and returns an CommandResult object' do
      subject.should_receive(:ssh_exec).with('test command').
        and_return ssh_output
      Rosh::Shell::CommandResult.should_receive(:new).
        with(nil, 0, ssh_output.stdout, ssh_output.stderr).and_return outcome

      o = subject.send(:run, 'test command')
      o.should == outcome
    end
  end


  describe '#cp' do
    let(:source) { '/home/path' }

    context 'source does not exist' do
      let(:result) do
        r = double 'Rosh::Shell::CommandResult'
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
        r = double 'Rosh::Shell::CommandResult'
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
        r = double 'Rosh::Shell::CommandResult'
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
        r = double 'Rosh::Shell::CommandResult'
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
        r = double 'Rosh::Shell::CommandResult'
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
      r = double 'Rosh::Shell::CommandResult'
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
