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
    e.stub(:kind_of?).and_return(true)
    e.stub(:wrapped).and_return actual_exception
    e.stub(:result).and_return result

    e
  end

  let(:actual_exception) do
    double 'SocketError or something'
  end

  describe '#initialize' do
    context 'ssh_output is a Net::SSH::Simple::Error' do
      subject do
        Rosh::CommandResult.new(error)
      end

      its(:ruby_object) { should == error }
      its(:exit_status) { should be_nil }
      its(:ssh_result) { should be_nil }
    end

    context 'ssh_output is a Net::SSH::Simple::Result' do
      subject { Rosh::CommandResult.new(result) }

      its(:ruby_object) { should == result }
      its(:exit_status) { should be_nil }
      its(:ssh_result) { should be_nil }
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

      it 'returns a Hash' do
        Hash[subject.to_hash.sort].should == {
          ruby_object: error,
          exit_status: nil,
          ssh_result: nil
        }
      end
    end

    context 'as a result' do
      subject { Rosh::CommandResult.new(result) }

      it 'returns a Hash' do
        Hash[subject.to_hash.sort].should == {
          ruby_object: result,
          exit_status: nil,
          ssh_result: nil
        }
      end
    end
  end

  describe '#to_json' do
    context 'as an error' do
      subject { Rosh::CommandResult.new(error) }

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
