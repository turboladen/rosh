require 'memfs'
require 'rosh/shell/adapters/local'

RSpec.describe Rosh::Shell::Adapters::Local do
  subject(:shell) do
    Object.new.extend(described_class)
  end

  before do
    allow(shell).to receive(:bad_info)
  end

  describe '#cd' do
    before do
      MemFs.activate!
    end

    after do
      MemFs.deactivate!
    end

    context 'directory does not exist' do
      before { @r = shell.cd('blah') }

      specify { @r.should be_a Errno::ENOENT }
      specify { shell.last_exit_status.should eq 1 }
      specify { shell.last_result.should eq @r }
    end

    context 'directory is a file' do
      before do
        Dir.should_receive(:chdir).with(File.expand_path('blah')).
          and_raise Errno::ENOTDIR

        @r = shell.cd('blah')
      end

      specify { @r.should be_a Errno::ENOTDIR }
      specify { shell.last_exit_status.should eq 1 }
      specify { shell.last_result.should eq @r }
    end

    context 'directory exists' do
      before { @r = shell.cd('/') }

      specify { @r.should be_true }
      specify { shell.last_exit_status.should eq 0 }
      specify { shell.last_result.should eq @r }
    end
  end

  describe '#exec' do
    context 'invalid command' do
      before do
        PTY.should_receive(:spawn).and_raise
        @r = shell.exec('bskldfjlsk')
      end

      specify { @r.should be_kind_of Exception }
      specify { shell.last_exit_status.should eq 1 }
      specify { shell.last_result.should eq @r }
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
        @r = shell.exec('ls')
      end

      specify { @r.should eq 'command output' }
      specify { pending; shell.last_exit_status.should eq $CHILD_STATUS.exitstatus }
      specify { shell.last_result.should eq @r }
    end
  end

  describe '#pwd' do
    let(:output) { double 'output', to_s: 'the dir' }

    before do
      expect(shell).to receive(:process).with(:pwd) { output }
      @r = shell.pwd
    end

    specify { expect(@r).to eq output  }
  end

  describe '#ruby' do
    context 'the executed code raises an exception' do
      before { @r = shell.ruby 'raise' }

      specify { @r.should be_a RuntimeError }
      specify { shell.last_exit_status.should eq 1 }
      specify { shell.last_result.should eq @r }
    end

    context 'the executed code saves a value to a variable' do
      before { @r = shell.ruby 'var = [1, 2, 3]' }

      specify { @r.should eq [1, 2, 3] }
      specify { shell.last_exit_status.should eq 0 }
      specify { shell.last_result.should eq @r }

      it 'allows subsequent #ruby calls to access that saved variable' do
        expect { shell.ruby 'var' }.to_not raise_exception
      end
    end
  end

  describe '#ls' do
    let(:path) { '/home/path' }

    context 'path exists' do
      let(:file_system_object) do
        double 'Rosh::LocalBaseObject'
      end

      before do
        Dir.should_receive(:entries).with(path).and_return [path]
        Rosh::FileSystem.should_receive(:create).and_return file_system_object
      end

      context 'path is relative' do
        before do
          shell.should_receive(:preprocess_path).with('path').and_return path
          @r = shell.ls('path')
        end

        specify { @r.should eq [file_system_object] }
        specify { shell.last_exit_status.should eq 0 }
        specify { shell.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          shell.should_receive(:preprocess_path).with(path).and_return path
          @r = shell.ls('/home/path')
        end

        specify { @r.should eq [file_system_object] }
        specify { shell.last_exit_status.should eq 0 }
        specify { shell.last_result.should eq @r }
      end
    end

    context 'path does not exist' do
      before do
        Dir.should_receive(:entries).with('/home/path').and_raise Errno::ENOENT
      end

      context 'path is relative' do
        before do
          shell.should_receive(:preprocess_path).with('path').and_return path
          @r = shell.ls('path')
        end

        specify { @r.should be_a Errno::ENOENT }
        specify { shell.last_exit_status.should eq 1 }
        specify { shell.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          shell.should_receive(:preprocess_path).with('/home/path').and_return path
          @r = shell.ls('/home/path')
        end

        specify { @r.should be_a Errno::ENOENT }
        specify { shell.last_exit_status.should eq 1 }
        specify { shell.last_result.should eq @r }
      end
    end

    context 'path is not a directory' do
      before do
        Dir.should_receive(:entries).with('/home/path').and_raise Errno::ENOTDIR
      end

      context 'path is relative' do
        before do
          shell.should_receive(:preprocess_path).with('path').and_return path
          @r = shell.ls('path')
        end

        specify { @r.should be_a Errno::ENOTDIR }
        specify { shell.last_exit_status.should eq 1 }
        specify { shell.last_result.should eq @r }
      end

      context 'path is absolute' do
        before do
          shell.should_receive(:preprocess_path).with('/home/path').and_return path
          @r = shell.ls('/home/path')
        end

        specify { @r.should be_a Errno::ENOTDIR }
        specify { shell.last_exit_status.should eq 1 }
        specify { shell.last_result.should eq @r }
      end
    end
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
      before { @r = shell.ps }

      specify { @r.should eq processes }
      specify { shell.last_exit_status.should eq 0 }
      specify { shell.last_result.should eq @r }
    end

    context 'valid name given' do
      before { @r = shell.ps(name: 'stuff') }

      specify { @r.should eq [processes.first] }
      specify { shell.last_exit_status.should eq 0 }
      specify { shell.last_result.should eq @r }
    end

    context 'non-existant process name given' do
      before { @r = shell.ps(name: 'lksdjflksdjfl') }

      specify { @r.should eq [] }
      specify { shell.last_exit_status.should eq 0 }
      specify { shell.last_result.should eq @r }
    end
  end
end
