require 'spec_helper'
require 'rosh/host'


describe 'Runs cd command in different variations' do
  subject do
    Rosh::Host.new 'localhost'
  end

  describe 'cd' do
    context 'no args' do
      context 'call directly' do
        before do
          @result = subject.shell.cd
        end

        it 'returns a Rosh::CommandResult' do
          @result.should be_a Rosh::CommandResult
        end

        it 'returns 0 exit code' do
          @result.exit_status.should be_zero
        end

        it 'has ruby_object that is a Hash of the current directory' do
          @result.ruby_object.should == Dir.home
        end
      end

      context 'exec' do
        before do
          @result = subject.shell.exec('cd')
        end

        it 'returns a Rosh::CommandResult' do
          @result.should be_a Rosh::CommandResult
        end

        it 'returns 0 exit code' do
          @result.exit_status.should be_zero
        end

        it 'has ruby_object that is an empty string' do
          @result.ruby_object.should == Dir.home
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
end
