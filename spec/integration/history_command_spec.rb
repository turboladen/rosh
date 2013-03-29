require 'spec_helper'
require 'rosh/host'


describe 'Runs history command in different variations' do
  subject do
    Rosh::Host.new 'localhost'
  end

  describe 'history' do
    context 'exec' do
      before do
        @result = subject.shell.exec('history')
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 1 exit code' do
        @result.status.should == 1
      end

      it 'has ruby_object that is the exception that occurred when running the command' do
        @result.ruby_object.should be_a_kind_of Exception
      end
    end

    context 'call directly' do
      before do
        @result = subject.shell.history
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 0 exit code' do
        @result.status.should be_zero
      end

      it 'has ruby_object that is a Hash of the current directory' do
        @result.ruby_object.should include 0 => {
          history: {
            args: [],
            options: {},
            block: nil
          }
        }
      end
    end

    context 'add_command' do
      it 'returns a Rosh::CommandResult' do
        pending
        subject.shell.add_command('cd')
        subject.shell.run_all
      end
    end
  end
end
