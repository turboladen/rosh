require 'spec_helper'
require 'rosh/file_system/file_system_controller'


describe Rosh::FileSystem::FileSystemController do
  subject do
    obj = described_class.new('test_host')
    obj.stub(:adapter) { fake_adapter }
    obj.stub(:current_shell) { shell }

    obj
  end

  let(:fake_adapter) { double 'Adapter' }
  let(:watched_object) { Object.new }
  let(:shell) { double 'Rosh::Shell', su?: false }

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
