require 'spec_helper'
require 'rosh/host'


describe 'Runs exec command in different variations' do
  subject do
    Rosh::Host.new 'localhost'
  end

  describe 'exec' do
    context 'call directly' do
      before do
        @result = subject.shell.exec "ps aux | grep -i #{File.basename($0)}"
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 0 exit code' do
        @result.exit_status.should be_zero
      end

      it 'has ruby_object that is a Hash of the current directory' do
        @result.ruby_object.should be_a String
        p @result.ruby_object
        @result.ruby_object.should include File.basename($0)
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
