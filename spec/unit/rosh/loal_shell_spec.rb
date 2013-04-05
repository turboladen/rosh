require 'spec_helper'
require 'rosh/local_shell'
require 'tempfile'


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

  describe '#cp' do
    context 'source does not exist' do
      before do
        FileUtils.should_receive(:cp).and_raise Errno::ENOENT
        @r = subject.cp('source', 'destination')
      end


      it 'returns a CommandResult with exit status 1' do
        @r.exit_status.should eq 1
      end

      it 'returns a CommandResult with ruby object a Errno::ENOENT' do
        @r.ruby_object.should be_a Errno::ENOENT
      end
    end

    context 'source is a directory' do
      before do
        FileUtils.should_receive(:cp).and_raise Errno::EISDIR
        @r = subject.cp('source', 'destination')
      end


      it 'returns a CommandResult with exit status 1' do
        @r.exit_status.should eq 1
      end

      it 'returns a CommandResult with ruby object a Errno::EISDIR' do
        @r.ruby_object.should be_a Errno::EISDIR
      end
    end

    context 'destination exists' do
      let(:dest) do
        Tempfile.new('rosh_test')
      end

      after do
        dest.unlink
      end

      it 'overwrites the destination' do
        subject.cp(__FILE__, dest.path)
        File.size(__FILE__).should == File.size(dest.path)
      end
    end
  end

  describe '#exec' do
    context 'invalid command' do
      before do
        subject.should_receive(:system).and_return nil
        @r = subject.exec('bskldfjlsk')
      end

      it 'returns a CommandResult with exit status 1' do
        @r.exit_status.should == 1
      end

      it 'returns a CommandResult with ruby object nil' do
        @r.ruby_object.should be_nil
      end
    end

    context 'valid command' do
      before do
        subject.should_receive(:system).and_return 'a file'
        @r = subject.exec('ls')
      end

      it 'returns a CommandResult with exit status 0' do
        @r.exit_status.should == 0
      end

      it 'returns a CommandResult with ruby object nil' do
        @r.ruby_object.should == 'a file'
      end
    end
  end

  describe '#ls' do
    let(:path) { '/home/path' }

    context 'path exists' do
      let(:file_system_object) do
        double 'Rosh::LocalFileSystemObject'
      end

      before do
        Dir.should_receive(:entries).with(path).and_return [path]
        Rosh::LocalFileSystemObject.should_receive(:create).
          and_return file_system_object
      end

      context 'path is relative' do
        before do
          subject.should_receive(:preprocess_path).with('path').and_return path
          @r = subject.ls('path')
        end

        it 'returns a CommandResult with exit status 0' do
          @r.exit_status.should eq 0
        end

        it 'returns a CommandResult with ruby object an Array of LocalFileSystemObjects' do
          @r.ruby_object.should eq [file_system_object]
        end
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          @r = subject.ls('/home/path')
        end

        it 'returns a CommandResult with exit status 0' do
          @r.exit_status.should eq 0
        end

        it 'returns a CommandResult with ruby object an Array of LocalFileSystemObjects' do
          @r.ruby_object.should eq [file_system_object]
        end
      end
    end

    context 'path does not exist' do
      before do
        Dir.should_receive(:entries).with('/home/path').and_raise Errno::ENOENT
      end

      context 'path is relative' do
        before do
          subject.should_receive(:preprocess_path).with('path').and_return path
          @r = subject.ls('path')
        end

        it 'returns a CommandResult with exit status 1' do
          @r.exit_status.should eq 1
        end

        it 'returns a CommandResult with ruby object an Errno::ENOENT' do
          @r.ruby_object.should be_a Errno::ENOENT
        end
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with('/home/path').and_return path
          @r = subject.ls('/home/path')
        end

        it 'returns a CommandResult with exit status 1' do
          @r.exit_status.should eq 1
        end

        it 'returns a CommandResult with ruby object an Errno::ENOENT' do
          @r.ruby_object.should be_a Errno::ENOENT
        end
      end
    end

    context 'path is not a directory' do
      before do
        Dir.should_receive(:entries).with('/home/path').and_raise Errno::ENOTDIR
      end

      context 'path is relative' do
        before do
          subject.should_receive(:preprocess_path).with('path').and_return path
          @r = subject.ls('path')
        end

        it 'returns a CommandResult with exit status 1' do
          @r.exit_status.should eq 1
        end

        it 'returns a CommandResult with ruby object an Errno::ENOTDIR' do
          @r.ruby_object.should be_a Errno::ENOTDIR
        end
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with('/home/path').and_return path
          @r = subject.ls('/home/path')
        end

        it 'returns a CommandResult with exit status 1' do
          @r.exit_status.should eq 1
        end

        it 'returns a CommandResult with ruby object an Errno::ENOTDIR' do
          @r.ruby_object.should be_a Errno::ENOTDIR
        end
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

  describe '#ps' do
    before do
      @r = subject.ps
    end

    it 'returns a CommandResult with exit status 0' do
      @r.exit_status.should be_zero
    end

    it 'returns a CommandResult with ruby object an Array of Struct::ProcTableStructs' do
      @r.ruby_object.should be_an Array
      @r.ruby_object.first.should be_a Struct::ProcTableStruct
    end
  end

  describe '#ruby' do
    context 'the executed code raises an exception' do
      before do
        @r = subject.ruby 'raise'
      end

      it 'returns a CommandResult with exit status 1' do
        @r.exit_status.should == 1
      end

      it 'returns a CommandResult with ruby object the exception that was raised' do
        @r.ruby_object.should be_a RuntimeError
      end
    end

    context 'the executed code saves a value to a variable' do
      before do
        @r = subject.ruby 'var = [1, 2, 3]'
      end

      it 'returns a CommandResult with exit status 0' do
        @r.exit_status.should == 0
      end

      it 'returns a CommandResult with ruby object the value that was saved' do
        @r.ruby_object.should == [1, 2, 3]
      end

      it 'allows subsequent #ruby calls to access that saved variable' do
        expect { subject.ruby 'var' }.to_not raise_exception
      end
    end
  end
end
