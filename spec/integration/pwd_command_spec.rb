require 'spec_helper'
require 'rosh/host'


describe 'Runs pwd command in different variations' do
  subject do
    Rosh::Host.new 'localhost'
  end

  describe 'pwd' do
    context 'execute' do
      before do
        @result = subject.shell.execute(%w[pwd])
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 0 exit code' do
        @result.exit_status.should be_zero
      end

      it 'has ruby_object that is a Hash of the current directory' do
        @result.ruby_object.should == File.expand_path(File.dirname(__FILE__) + '/../../')
      end
    end

    context 'call directly' do
      before do
        @result = subject.shell.pwd
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 0 exit code' do
        @result.exit_status.should be_zero
      end

      it 'has ruby_object that is a Hash of the current directory' do
        @result.ruby_object.should == File.expand_path(File.dirname(__FILE__) + '/../../')
      end
    end

    context 'add_command' do
      it 'returns a Rosh::CommandResult' do
        pending
        subject.shell.add_command('pwd')
        subject.shell.run_all
      end
    end
  end
end
