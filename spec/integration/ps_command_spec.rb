require 'spec_helper'
require 'rosh/host'


describe 'Runs ps command in different variations' do
  subject do
    Rosh::Host.new 'localhost'
  end

  describe 'ps' do
    context 'execute' do
      before do
        @result = subject.shell.execute(%w[ps])
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 0 exit code' do
        @result.status.should be_zero
      end

      it 'has ruby_object that is a Hash of the current process list' do
        @result.ruby_object.should be_a(Hash)
        @result.ruby_object.should_not be_empty
      end
    end

    context 'call directly' do
      before do
        @result = subject.shell.ps
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 0 exit code' do
        @result.status.should be_zero
      end

      it 'has ruby_object that is a Hash of the current directory' do
        @result.ruby_object.should be_a(Hash)
        @result.ruby_object.should_not be_empty
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
