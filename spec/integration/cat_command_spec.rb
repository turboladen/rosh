require 'spec_helper'
require 'rosh/host'


describe 'Runs cat command in different variations' do
  subject do
    Rosh::Host.new 'localhost'
  end

  describe 'cp' do
    context 'exec' do
      before do
        @result = subject.shell.exec(%[cat #{__FILE__}])
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 0 exit code' do
        @result.status.should be_zero
      end

      it 'has ruby_object that is a String of the current file' do
        @result.ruby_object.should == File.read(__FILE__)
      end
    end

    context 'call directly' do
      before do
        @result = subject.shell.cat(__FILE__)
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 0 exit code' do
        @result.status.should be_zero
      end

      it 'has ruby_object that is a Hash of the current directory' do
        @result.ruby_object.should == File.read(__FILE__)
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
