require 'spec_helper'
require 'rosh/host/shells/remote'


describe Rosh::Host::Shells::Remote do
  let(:ssh) do
    double 'Net::SSH::Connection', close: true, :closed? => true
  end

  let(:hostname) { 'testhost' }
  let(:outcome) { double 'Rosh::CommandResult' }

  let(:ssh_output) do
    o = double 'SSHResult'
    o.stub(:exit_status).and_return 0
    o.stub(:stdout).and_return ''
    o.stub(:stderr).and_return ''

    o
  end

  let(:internal_pwd) { '/home' }
  subject { Rosh::Host::Shells::Remote.new(hostname) }

  before do
    Net::SSH.stub(:start).and_return(ssh)
    Rosh::Host::Shells::Remote.log = false
    subject.instance_variable_set(:@internal_pwd, internal_pwd)
  end

  after do
    Net::SSH.unstub(:start)
  end

  describe '#initialize' do
    context 'no options passed in' do
      its(:hostname) { should eq 'testhost' }
      its(:user) { should eq Etc.getlogin }
    end

    context ':user option passed in' do
      subject { Rosh::Host::Shells::Remote.new('test', user: 'bobo') }
      its(:hostname) { should eq 'test' }
      its(:user) { should eq 'bobo' }
      its(:options) { should eq({}) }
    end

    context ':timeout option passed in' do
      subject { Rosh::Host::Shells::Remote.new('test', timeout: 1) }
      its(:hostname) { should eq 'test' }
      its(:user) { should eq Etc.getlogin }
      its(:options) { should eq(timeout: 1) }
    end

    context ':meow option passed in' do
      subject { Rosh::Host::Shells::Remote.new('test', meow: 'cat') }
      its(:hostname) { should eq 'test' }
      its(:user) { should eq Etc.getlogin }
      its(:options) { should eq(meow: 'cat') }
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
      before do
        subject.instance_variable_set(:@options, timeout: 1800)
      end

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

  describe '#upload' do
    context 'all goes well' do
      it 'runs the command and returns an CommandResult object' do
        subject.should_receive(:scp).with('test file', '/destination')
        Rosh::CommandResult.should_receive(:new).
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

          Rosh::CommandResult.should_receive(:new).with(nil, 0).and_return outcome

          subject.upload('test file', '/destination')
          subject.options[:password].should == 'test password'
        end
      end

      context 'unsuccessful password is entered' do
        before do
          subject.should_receive(:scp).and_raise Net::SSH::AuthenticationFailed
        end

        it 'returns a CommandResult with the exception' do
          subject.should_receive(:prompt).once.and_return 'test password'
          subject.should_receive(:bad_info).with 'Authentication failed.'

          Rosh::CommandResult.should_receive(:new) do |ruby_obj, exit_status|
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
        subject.should_receive(:exec).
          with('cp /tmp/rosh_upload /destination && rm /tmp/rosh_upload')

        subject.upload('tmp file', '/destination')
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
        r = double 'Rosh::CommandResult'
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
        r = double 'Rosh::CommandResult'
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
        r = double 'Rosh::CommandResult'
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
      Rosh::CommandResult.should_receive(:new).
        with(nil, 0, ssh_output.stdout, ssh_output.stderr).and_return outcome

      o = subject.send(:run, 'test command')
      o.should == outcome
    end
  end
end
