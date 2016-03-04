require 'rosh/file_system'

RSpec.describe Rosh::FileSystem do
  subject(:file_system) { Rosh::FileSystem.new('test_host') }

  let(:current_host) do
    instance_double 'Rosh::Host', local?: true
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
      expect(subject).to receive(:subscribe).with(fs_object, :update)

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
        it 'raises a UnknownObjectType exception' do
          expect { file_system[meow: 'stuff'] }.
            to raise_error(Rosh::FileSystem::UnknownObjectType,
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
        expect(file_system).to receive(:file).with(filename)
        file_system.build filename
      end
    end

    context 'path is a directory' do
      before do
        allow(file_system).to receive(:file?) { false }
        allow(file_system).to receive(:directory?) { true }
      end

      it 'calls #directory with the path' do
        expect(file_system).to receive(:directory).with(filename)
        file_system.build filename
      end
    end

    context 'path is a symbolic link' do
      before do
        allow(file_system).to receive(:file?) { false }
        allow(file_system).to receive(:directory?) { false }
        allow(file_system).to receive(:symbolic_link?) { true }
      end

      it 'calls #symbolic_link with the path' do
        expect(file_system).to receive(:symbolic_link).with(filename)
        file_system.build filename
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
        expect(file_system).to receive(:character_device).with(filename)
        file_system.build filename
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
        expect(file_system).to receive(:block_device).with(filename)
        file_system.build filename
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
        expect(file_system).to receive(:object).with(filename)
        file_system.build filename
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

        subject.chroot(new_root)
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

        subject.chroot(new_root)
      end
    end
  end

  describe '#umask=' do
    before do
      allow(subject).to receive(:adapter) { fake_adapter }
    end

    it 'runs idempotently and delegates to the adapter' do
      expect(subject).to receive(:umask) { 12 }
      expect(subject).to receive(:run_idempotent_command).and_yield
      expect(fake_adapter).to receive(:umask).with 12

      subject.umask = 12
    end
  end
end
