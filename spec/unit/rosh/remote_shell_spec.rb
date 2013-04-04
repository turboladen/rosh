require 'spec_helper'
require 'rosh/remote_shell'


describe Rosh::RemoteShell do
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
    Rosh::RemoteShell.new(hostname)
  end

  before do
    Net::SSH::Simple.stub(:new).and_return(ssh)
    Rosh::RemoteShell.log = false
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
      subject { Rosh::RemoteShell.new('test', user: 'bobo') }
      its(:options) { should eq(user: 'bobo', timeout: 1800) }
    end

    context ':timeout option passed in' do
      subject { Rosh::RemoteShell.new('test', timeout: 1) }
      its(:options) { should eq(user: Etc.getlogin, timeout: 1) }
    end

    context ':meow option passed in' do
      subject { Rosh::RemoteShell.new('test', meow: 'cat') }
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
        result.ruby_object.should == 'some path'
        result.exit_status.should == 0
      end
    end

    context '@internal_pwd is set' do
      it 'does not run "pwd" over ssh, but returns @internal_pwd' do
        subject.should_not_receive(:run).with('pwd')

        result = subject.pwd
        result.should be_a Rosh::CommandResult
        result.ruby_object.should == '/home'
        result.exit_status.should == 0
      end
    end
  end

  describe '#cd' do
    context 'path is relative' do
      context 'path does not exist' do
        let(:result) do
          r = double 'Rosh::CommandResult'
          r.stub(:exit_status).and_return 1

          r
        end

        it 'returns a CommandResult with exit status 1' do
          subject.should_receive(:run).with('cd /home/path && pwd').and_return result

          r = subject.cd('path')
          r.exit_status.should eq 1
        end
      end

      context 'path exists' do
        let(:result) do
          r = double 'Rosh::CommandResult'
          r.stub(:exit_status).and_return 0
          r.stub(:ruby_object).and_return 'new path'
          r.stub(:ssh_result).and_return 'ssh output'

          r
        end

        it 'returns a CommandResult with exit status 1' do
          subject.should_receive(:run).with('cd /home/path && pwd').and_return result

          r = subject.cd('path')
          r.exit_status.should eq 0
        end
      end
    end

    context 'path is absolute' do
      context 'path does not exist' do
        let(:result) do
          r = double 'Rosh::CommandResult'
          r.stub(:exit_status).and_return 1

          r
        end

        it 'returns a CommandResult with exit status 1' do
          subject.should_receive(:run).with('cd /etc/init.d && pwd').and_return result

          r = subject.cd('/etc/init.d')
          r.exit_status.should eq 1
        end

      end
    end

    context 'path exists' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:ruby_object).and_return 'new path'
        r.stub(:ssh_result).and_return 'ssh output'

        r
      end

      it 'returns a CommandResult with exit status 1' do
        subject.should_receive(:run).with('cd /etc/init.d && pwd').and_return result

        r = subject.cd('/etc/init.d')
        r.exit_status.should eq 0
      end
    end
  end

  describe '#cat' do
    context 'path is relative' do
      context 'path does not exist' do
        let(:result) do
          r = double 'Rosh::CommandResult'
          r.stub(:exit_status).and_return 1

          r
        end

        it 'returns a CommandResult with exit status 1' do
          subject.should_receive(:run).with('cat /home/path').and_return result

          r = subject.cat('path')
          r.exit_status.should eq 1
        end
      end

      context 'path exists' do
        let(:result) do
          r = double 'Rosh::CommandResult'
          r.stub(:exit_status).and_return 0
          r.stub(:ruby_object).and_return 'new path'
          r.stub(:ssh_result).and_return 'ssh output'

          r
        end

        it 'returns a CommandResult with exit status 1' do
          subject.should_receive(:run).with('cat /home/path').and_return result

          r = subject.cat('path')
          r.exit_status.should eq 0
        end
      end
    end

    context 'path is absolute' do
      context 'path does not exist' do
        let(:result) do
          r = double 'Rosh::CommandResult'
          r.stub(:exit_status).and_return 1

          r
        end

        it 'returns a CommandResult with exit status 1' do
          subject.should_receive(:run).with('cat /etc/hosts').and_return result

          r = subject.cat('/etc/hosts')
          r.exit_status.should eq 1
        end
      end
    end

    context 'path exists' do
      let(:result) do
        r = double 'Rosh::CommandResult'
        r.stub(:exit_status).and_return 0
        r.stub(:ruby_object).and_return 'new path'
        r.stub(:ssh_result).and_return 'ssh output'

        r
      end

      it 'returns a CommandResult with exit status 1' do
        subject.should_receive(:run).with('cat /etc/hosts').and_return result

        r = subject.cat('/etc/hosts')
        r.exit_status.should eq 0
      end
    end
  end
end
