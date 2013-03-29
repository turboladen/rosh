require 'spec_helper'
require 'rosh/host'


describe 'Runs cp command in different variations' do
  subject do
    Rosh::Host.new 'localhost'
  end

  describe 'cp' do
    let(:tmpfile) do
      Tempfile.new('rosh_cp_spec')
    end

    context 'exec' do
      before do
        @result = subject.shell.exec(%[cp #{__FILE__} #{tmpfile.path}])
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 0 exit code' do
        @result.status.should be_zero
      end

      it 'has ruby_object that is a Hash of the current directory' do
        @result.ruby_object.should == ''
      end
    end

    context 'call directly' do
      before do
        @result = subject.shell.cp(__FILE__, tmpfile.path)
      end

      it 'returns a Rosh::CommandResult' do
        @result.should be_a Rosh::CommandResult
      end

      it 'returns 0 exit code' do
        @result.status.should be_zero
      end

      it 'has ruby_object that is a Hash of the current directory' do
        @result.ruby_object.should == true
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
