require 'spec_helper'
require 'rosh/host/shells/local'


describe Rosh::Host::WrapperMethods::Local do
  subject do
    Rosh::Host::Shells::Local.new
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
end
