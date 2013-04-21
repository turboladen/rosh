require 'spec_helper'
require 'rosh/host/shells/local'
require 'tempfile'


describe Rosh::Host::Shells::Local do
  subject do
    Rosh::Host::Shells::Local.new
  end

  describe '#cd' do
    context 'directory does not exist' do
      before { @r = subject.cd('blah') }

      specify { @r.should be_a Errno::ENOENT }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'directory is a file' do
      before do
        Dir.should_receive(:chdir).with(File.expand_path('blah')).
          and_raise Errno::ENOTDIR

        @r = subject.cd('blah')
      end

      specify { @r.should be_a Errno::ENOTDIR }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'directory exists' do
      before { @r = subject.cd('/') }

      specify { @r.should be_true }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end
  end

  describe '#cp' do
    context 'source does not exist' do
      before do
        FileUtils.should_receive(:cp).and_raise Errno::ENOENT
        @r = subject.cp('source', 'destination')
      end

      specify { @r.should be_a Errno::ENOENT }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'source is a directory' do
      before do
        FileUtils.should_receive(:cp).and_raise Errno::EISDIR
        @r = subject.cp('source', 'destination')
      end

      specify { @r.should be_a Errno::EISDIR }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'destination exists' do
      let(:dest) do
        Tempfile.new('rosh_test')
      end

      before do
        at_exit { dest.unlink }
      end

      before { @r = subject.cp(__FILE__, dest.path) }

      it 'overwrites the destination' do
        File.size(__FILE__).should == File.size(dest.path)
      end

      specify { @r.should be_true }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end
  end

  describe '#exec' do
    context 'invalid command' do
      before do
        PTY.should_receive(:spawn).and_raise
        @r = subject.exec('bskldfjlsk')
      end

      specify { @r.should be_kind_of Exception }
      specify { subject.last_exit_status.should eq $?.exitstatus }
      specify { subject.last_result.should eq @r }
    end

    context 'valid command' do
      let(:reader) do
        r = double 'PTY reader'
        r.should_receive(:readpartial).and_return 'command output'
        r.should_receive(:readpartial).and_raise EOFError

        r
      end

      before do
        PTY.should_receive(:spawn).and_yield reader, nil, 123
        Process.should_receive(:wait).with(123)
        @r = subject.exec('ls')
      end

      specify { @r.should eq 'command output' }
      specify { subject.last_exit_status.should eq $?.exitstatus }
      specify { subject.last_result.should eq @r }
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
        Rosh::Host::LocalFileSystemObject.should_receive(:create).
          and_return file_system_object
      end

      context 'path is relative' do
        before do
          subject.should_receive(:preprocess_path).with('path').and_return path
          @r = subject.ls('path')
        end

        specify { @r.should eq [file_system_object] }
        specify { subject.last_exit_status.should eq 0 }
        specify { subject.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with(path).and_return path
          @r = subject.ls('/home/path')
        end

        specify { @r.should eq [file_system_object] }
        specify { subject.last_exit_status.should eq 0 }
        specify { subject.last_result.should eq @r }
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

        specify { @r.should be_a Errno::ENOENT }
        specify { subject.last_exit_status.should eq 1 }
        specify { subject.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with('/home/path').and_return path
          @r = subject.ls('/home/path')
        end

        specify { @r.should be_a Errno::ENOENT }
        specify { subject.last_exit_status.should eq 1 }
        specify { subject.last_result.should eq @r }
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

        specify { @r.should be_a Errno::ENOTDIR }
        specify { subject.last_exit_status.should eq 1 }
        specify { subject.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          subject.should_receive(:preprocess_path).with('/home/path').and_return path
          @r = subject.ls('/home/path')
        end

        specify { @r.should be_a Errno::ENOTDIR }
        specify { subject.last_exit_status.should eq 1 }
        specify { subject.last_result.should eq @r }
      end
    end
  end

  describe '#pwd' do
    before do
      Dir.should_receive(:new).with(subject.
        instance_variable_get(:@internal_pwd)).and_return 'some dir'
      @r = subject.pwd
    end

    specify { @r.should eq 'some dir' }
    specify { subject.last_exit_status.should eq 0 }
    specify { subject.last_result.should eq @r }
  end

  describe '#ps' do
    let(:processes) do
      [
        double('Struct::ProcTableStruct', cmdline: '/usr/stuff'),
        double('Struct::ProcTableStruct', cmdline: '/usr/bin/things')
      ]
    end

    before do
      Sys::ProcTable.should_receive(:ps).and_return processes
    end

    context 'no name given' do
      before { @r = subject.ps }

      specify { @r.should eq processes }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end

    context 'valid name given' do
      before { @r = subject.ps(name: 'stuff') }

      specify { @r.should eq [processes.first] }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end

    context 'non-existant process name given' do
      before { @r = subject.ps(name: 'lksdjflksdjfl') }

      specify { @r.should eq [] }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end
  end

  describe '#ruby' do
    context 'the executed code raises an exception' do
      before { @r = subject.ruby 'raise' }

      specify { @r.should be_a RuntimeError }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'the executed code saves a value to a variable' do
      before { @r = subject.ruby 'var = [1, 2, 3]' }

      specify { @r.should eq [1, 2, 3] }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }

      it 'allows subsequent #ruby calls to access that saved variable' do
        expect { subject.ruby 'var' }.to_not raise_exception
      end
    end
  end
end
