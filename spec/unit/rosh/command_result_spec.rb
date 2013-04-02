require 'spec_helper'
require 'rosh/command_result'


describe Rosh::CommandResult do
  let(:result) do
    r = double 'Net::SSH::Simple::Result'
    r.stub(:stdout).and_return 'stdout'
    r.stub(:stderr).and_return 'stderr'
    r.stub(:cmd).and_return 'cmd'
    r.stub(:start_at).and_return 'start_at'
    r.stub(:finish_at).and_return 'finish_at'
    r.stub(:last_event_at).and_return 'last_event_at'
    r.stub(:last_keepalive_at).and_return 'last_keepalive_at'
    r.stub(:opts).and_return 'opts'
    r.stub(:exit_code).and_return 'exit_code'

    r
  end

  let(:error) do
    e = double 'Net::SSH::Simple::Error'
    e.stub(:is_a?).and_return(Net::SSH::Simple::Error)
    e.stub(:wrapped).and_return actual_exception
    e.stub(:result).and_return result

    e
  end

  let(:actual_exception) do
    double 'SocketError or something'
  end

  let(:expected_hash) do
    {
      command: 'cmd',
      exit_code: 'exit_code',
      finished_at: 'finish_at',
      last_event_at: 'last_event_at',
      last_keepalive_at: 'last_keepalive_at',
      ssh_options: 'opts',
      started_at: 'start_at',
      exit_status: nil,
      stderr: 'stderr',
      stdout: 'stdout',
    }
  end

  describe '#initialize' do
    context 'ssh_output is a Net::SSH::Simple::Error' do
      subject do
        Rosh::CommandResult.new(error)
      end

      it 'saves the exception accessible at #exception' do
        subject.exception.should == actual_exception
      end

      it 'uses values from #result to populate its attributes' do
        subject.stdout.should == 'stdout'
        subject.stderr.should == 'stderr'
        subject.command.should == 'cmd'
        subject.started_at.should == 'start_at'
        subject.finished_at.should == 'finish_at'
        subject.last_event_at.should == 'last_event_at'
        subject.last_keepalive_at.should == 'last_keepalive_at'
        subject.ssh_options.should == 'opts'
        subject.exit_code.should == 'exit_code'
      end

      context 'with exit_status param' do
        subject { Rosh::CommandResult.new(error, :test) }
        its(:exit_status) { should == :failure }
      end

      context 'without exit_status param' do
        its(:exit_status) { should == :failure }
      end
    end

    context 'ssh_output is a Net::SSH::Simple::Result' do
      subject { Rosh::CommandResult.new(result) }

      it 'uses values from #result to populate its attributes' do
        subject.stdout.should == 'stdout'
        subject.stderr.should == 'stderr'
        subject.command.should == 'cmd'
        subject.started_at.should == 'start_at'
        subject.finished_at.should == 'finish_at'
        subject.last_event_at.should == 'last_event_at'
        subject.last_keepalive_at.should == 'last_keepalive_at'
        subject.ssh_options.should == 'opts'
        subject.exit_code.should == 'exit_code'
      end

      context 'with exit_status param' do
        subject { Rosh::CommandResult.new(result, :test) }
        its(:exit_status) { should == :test }
      end

      context 'without exit_status param' do
        its(:exit_status) { should be_nil }
      end
    end
  end

  describe '#exception?' do
    context 'an exception was passed in' do
      subject { Rosh::CommandResult.new(error) }
      specify { subject.exception?.should be_true }
    end

    context 'an exception was not passed in' do
      subject { Rosh::CommandResult.new(result) }
      specify { subject.exception?.should be_false }
    end
  end

  describe '#to_hash' do
    context 'as an error' do
      subject { Rosh::CommandResult.new(error) }

      before do
        expected_hash[:exception] = actual_exception
        expected_hash[:exit_status] = :failure
      end

      it 'returns a Hash' do
        Hash[subject.to_hash.sort].should == expected_hash
      end
    end

    context 'as a result' do
      subject { Rosh::CommandResult.new(result) }

      it 'returns a Hash' do
        Hash[subject.to_hash.sort].should == expected_hash
      end
    end
  end

  describe '#to_json' do
    context 'as an error' do
      subject { Rosh::CommandResult.new(error) }

      before do
        expected_hash[:exception] = actual_exception
        expected_hash[:exit_status] = :failure
      end

      it 'returns a String of JSON' do
        json = subject.to_json
        json.should be_a String
        expect { JSON(json) }.to_not raise_error JSON::ParserError
      end
    end

    context 'as a result' do
      subject { Rosh::CommandResult.new(result) }

      it 'returns a String of JSON' do
        json = subject.to_json
        json.should be_a String
        expect { JSON(json) }.to_not raise_error JSON::ParserError
      end
    end
  end

  describe '#to_yaml' do
    context 'as an error' do
      subject { Rosh::CommandResult.new(error) }

      before do
        expected_hash[:exception] = actual_exception
        expected_hash[:exit_status] = :failure
      end

      it 'returns a String of YAML' do
        yaml = subject.to_yaml
        yaml.should be_a String
        expect { YAML.load(yaml) }.to_not raise_error TypeError
      end
    end

    context 'as a result' do
      subject { Rosh::CommandResult.new(result) }

      it 'returns a String of JSON' do
        yaml = subject.to_yaml
        yaml.should be_a String
        expect { YAML.load(yaml) }.to_not raise_error TypeError
      end
    end
  end
end
