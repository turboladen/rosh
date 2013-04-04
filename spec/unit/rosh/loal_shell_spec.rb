require 'spec_helper'
require 'rosh/local_shell'


describe Rosh::LocalShell do
  describe '#cat' do
    context 'file does not exist' do
      it 'returns a CommandResult with ruby_object a Errno::ENOENT' do
        r = subject.cat('blah')

        r.should be_a Rosh::CommandResult
        r.exit_status.should eq 1
        r.ruby_object.should be_a Errno::ENOENT
      end
    end

    context 'file is a directory' do
      before do
        subject.should_receive(:open).with(File.expand_path('blah')).
          and_raise Errno::EISDIR
      end

      it 'returns a CommandResult with ruby_object a Errno::EISDIR' do
        r = subject.cat('blah')

        r.should be_a Rosh::CommandResult
        r.exit_status.should eq 1
        r.ruby_object.should be_a Errno::EISDIR
      end
    end

    context 'file exists' do
      it 'returns a CommandResult with ruby_object the contents of the file' do
        r = subject.cat(__FILE__)

        r.should be_a Rosh::CommandResult
        r.ruby_object.should be_a String
        r.exit_status.should eq 0
      end
    end
  end

  describe '#cd' do
    context 'directory does not exist' do
      it 'returns a CommandResult with ruby_object a Errno::ENOENT' do
        r = subject.cd('blah')

        r.should be_a Rosh::CommandResult
        r.exit_status.should eq 1
        r.ruby_object.should be_a Errno::ENOENT
      end
    end

    context 'directory is a file' do
      before do
        Dir.should_receive(:chdir).with(File.expand_path('blah')).
          and_raise Errno::ENOTDIR
      end

      it 'returns a CommandResult with ruby_object a Errno::EISDIR' do
        r = subject.cd('blah')

        r.should be_a Rosh::CommandResult
        r.exit_status.should eq 1
        r.ruby_object.should be_a Errno::ENOTDIR
      end
    end

    context 'directory exists' do
      it 'returns a CommandResult with ruby_object the new Dir' do
        r = subject.cd('/')

        r.should be_a Rosh::CommandResult
        r.ruby_object.should be_a Dir
        r.exit_status.should eq 0
      end
    end
  end

  describe '#pwd' do
    before do
      subject.instance_variable_set(:@internal_pwd, 'some dir')
    end

    it 'returns a CommandResult with ruby_object @internal_pwd' do
      r = subject.pwd
      r.should be_a Rosh::CommandResult
      r.exit_status.should be_zero
      r.ruby_object.should == 'some dir'
    end
  end
end
