require 'spec_helper'
require 'rosh/ssh'


describe Rosh::SSH do
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
    Rosh::SSH.new(hostname)
  end

  before do
    Net::SSH::Simple.stub(:new).and_return(ssh)
    Rosh::SSH.log = false
  end

  after do
    Net::SSH::Simple.unstub(:new)
  end

  describe '#initialize' do
    context 'no options passed in' do
      its(:options) { should eq(user: Etc.getlogin, timeout: 1800) }
    end

    context ':user option passed in' do
      subject { Rosh::SSH.new('test', user: 'bobo') }
      its(:options) { should eq(user: 'bobo', timeout: 1800) }
    end

    context ':timeout option passed in' do
      subject { Rosh::SSH.new('test', timeout: 1) }
      its(:options) { should eq(user: Etc.getlogin, timeout: 1) }
    end

    context ':meow option passed in' do
      subject { Rosh::SSH.new('test', meow: 'cat') }
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
end
