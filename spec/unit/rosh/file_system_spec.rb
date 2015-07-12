require 'rosh/file_system'

RSpec.describe Rosh::FileSystem do
  subject(:file_system) { Rosh::FileSystem.new('test_host') }

  let(:current_host) do
    double 'Host', local?: true
  end

  let(:fs_object) { double 'FileSystem::FakeObject' }
  let(:fake_adapter) { double 'Adapter' }
  let(:watched_object) { Object.new }

  before do
    Rosh::FileSystem.any_instance.stub(:current_host) { current_host }
  end

  describe '#[]' do
    it 'adds itself as an observer of the new object' do
      filename = 'the file'
      allow(file_system).to receive(:file).with(filename) { fs_object }
      expect(fs_object).to receive(:add_observer)

      file_system[file: filename]
    end

    context 'path is a Hash' do
      before do
        allow(fs_object).to receive(:add_observer)
      end

      context ':file' do
        it 'calls #file with the Hash value' do
          filename = 'the file'
          expect(file_system).to receive(:file).with(filename) { fs_object }
          file_system[file: filename]
        end
      end

      context ':dir' do
        it 'calls #directory with the Hash value' do
          filename = 'the dir'
          expect(file_system).to receive(:directory).with(filename) { fs_object }
          file_system[dir: filename]
        end
      end

      context ':directory' do
        it 'calls #directory with the Hash value' do
          filename = 'the dir'
          expect(file_system).to receive(:directory).with(filename) { fs_object }
          file_system[directory: filename]
        end
      end

      context 'some other hash key' do
        it 'raises a UnknownResourceType exception' do
          expect { file_system[meow: 'stuff'] }.
            to raise_error(Rosh::FileSystem::UnknownResourceType,
            "Resource type 'meow' does not exist."
          )
        end
      end
    end

    context 'path is not a Hash' do
      before do
        allow(fs_object).to receive(:add_observer)
      end

      it 'calls #build' do
        filename = 'the dir'
        expect(file_system).to receive(:build).with(filename) { fs_object }
        file_system[filename]
      end
    end
  end

  describe 'build' do
    let(:filename) { 'the thing' }

    context 'path is a file' do
      before { allow(file_system).to receive(:file?) { true } }

      it 'calls #file with the path' do
        expect(file_system).to receive(:file).with(filename).and_call_original
        file = file_system.build filename
        expect(file).to be_a Rosh::FileSystem::File
      end
    end

    context 'path is a directory' do
      before do
        allow(file_system).to receive(:file?) { false }
        allow(file_system).to receive(:directory?) { true }
      end

      it 'calls #directory with the path' do
        expect(file_system).to receive(:directory).with(filename).and_call_original
        dir = file_system.build filename
        expect(dir).to be_a Rosh::FileSystem::Directory
      end
    end

    context 'path is a symbolic link' do
      before do
        allow(file_system).to receive(:file?) { false }
        allow(file_system).to receive(:directory?) { false }
        allow(file_system).to receive(:symbolic_link?) { true }
      end

      it 'calls #symbolic_link with the path' do
        expect(file_system).to receive(:symbolic_link).with(filename).and_call_original
        symlink = file_system.build filename
        expect(symlink).to be_a Rosh::FileSystem::SymbolicLink
      end
    end

    context 'path is a character device' do
      before do
        allow(file_system).to receive(:file?) { false }
        allow(file_system).to receive(:directory?) { false }
        allow(file_system).to receive(:symbolic_link?) { false }
        allow(file_system).to receive(:character_device?) { true }
      end

      it 'calls #character_device with the path' do
        expect(file_system).to receive(:character_device).with(filename).and_call_original
        chardev = file_system.build filename
        expect(chardev).to be_a Rosh::FileSystem::CharacterDevice
      end
    end

    context 'path is a block device' do
      before do
        allow(file_system).to receive(:file?) { false }
        allow(file_system).to receive(:directory?) { false }
        allow(file_system).to receive(:symbolic_link?) { false }
        allow(file_system).to receive(:character_device?) { false }
        allow(file_system).to receive(:block_device?) { true }
      end

      it 'calls #block_device with the path' do
        expect(file_system).to receive(:block_device).with(filename).and_call_original
        blockdev = file_system.build filename
        expect(blockdev).to be_a Rosh::FileSystem::BlockDevice
      end
    end

    context 'path is neither a file nor a directory' do
      before do
        allow(file_system).to receive(:file?) { false }
        allow(file_system).to receive(:directory?) { false }
        allow(file_system).to receive(:symbolic_link?) { false }
        allow(file_system).to receive(:character_device?) { false }
        allow(file_system).to receive(:block_device?) { false }
      end

      it 'creates a FileSystem::Object' do
        expect(file_system).to receive(:object).with(filename).and_call_original
        obj = file_system.build filename
        expect(obj).to be_a Rosh::FileSystem::Object
      end
    end
  end

  describe '#chroot' do
    before { subject.instance_variable_set(:@root_directory, 'the root') }

    context 'new root param is same as existing root' do
      it 'delegates to the adapter and does not notify observers' do
        new_root = 'the root'

        expect(fake_adapter).to receive(:chroot).with new_root
        expect(watched_object).to_not receive(:changed)
        expect(watched_object).to_not receive(:notify_observers)

        subject.chroot(new_root, watched_object)
      end
    end

    context 'new root param is different from existing root' do
      it 'delegates to the adapter and notifies observers' do
        new_root = 'new root'

        expect(fake_adapter).to receive(:chroot).with new_root
        expect(watched_object).to receive(:changed)
        expect(watched_object).to receive(:notify_observers).with(
          watched_object,
          attribute: :fs_root,
          old: 'the root', new: new_root, as_sudo: false
        )

        subject.chroot(new_root, watched_object)
      end
    end
  end

  describe '#umask' do
    before do
      expect(fake_adapter).to receive(:umask) { 12 }
    end

    context 'new umask param is same as existing umask' do
      it 'delegates to the adapter and does not notify observers' do
        new_umask = 12

        expect(fake_adapter).to receive(:umask).with new_umask
        expect(watched_object).to_not receive(:changed)
        expect(watched_object).to_not receive(:notify_observers)

        subject.umask(new_umask, watched_object)
      end
    end

    context 'new umask param is different from existing umask' do
      it 'delegates to the adapter and notifies observers' do
        new_umask = 123

        expect(fake_adapter).to receive(:umask).with new_umask
        expect(watched_object).to receive(:changed)
        expect(watched_object).to receive(:notify_observers).with(
          watched_object,
          attribute: :umask,
          old: 12, new: new_umask, as_sudo: false
        )

        subject.umask(new_umask, watched_object)
      end
    end
  end
end
