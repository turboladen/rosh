require 'rosh/file_system/base_methods'

RSpec.describe Rosh::FileSystem::BaseMethods do
  describe '#mode=' do
    before do
      subject.stub(:mode).and_return 644
      shell.stub(:last_exit_status).and_return 0
      shell.stub(:check_state_first?).and_return false
    end

    context 'new_mode is the same as the old mode' do
      context 'check state first' do
        before do
          shell.stub(:check_state_first?).and_return true
        end

        it 'does not run the command' do
          shell.should_not_receive(:exec).with 'chmod 644 /file'
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.mode = 644
        end
      end

      context 'do not check state first' do
        it 'runs the command but does not update observers' do
          shell.should_receive(:exec).with 'chmod 644 /file'
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.mode = 644
        end
      end
    end

    context 'new_mode is not the same as the old mode' do
      it 'runs the command and updates observers' do
        shell.should_receive(:exec).with 'chmod 755 /file'
        subject.should_receive(:changed)
        subject.should_receive(:notify_observers).
          with(subject, attribute: :mode, old: 644, new: 755, as_sudo: false)

        subject.mode = 755
      end
    end

    context 'command failed' do
      before do
        shell.stub(:last_exit_status).and_return 1
      end

      it 'runs the command but does not update observers' do
        shell.should_receive(:exec).with 'chmod 111 /file'
        subject.should_not_receive(:changed)
        subject.should_not_receive(:notify_observers)

        subject.mode = 111
      end
    end
  end

  describe '#delete' do
    before do
      shell.stub(:last_exit_status).and_return 0
      shell.stub(:check_state_first?).and_return false
      subject.stub(:exists?).and_return false
    end

    context 'object did not exist' do
      context 'check state first' do
        before do
          shell.stub(:check_state_first?).and_return true
        end

        it 'does not run the command' do
          shell.should_not_receive(:exec).with 'rm -rf /file'
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.delete
        end
      end

      context 'do not check state first' do
        it 'runs the command but does not update observers' do
          shell.should_receive(:exec).with 'rm -rf /file'
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.delete
        end
      end
    end

    context 'object existed' do
      before do
        subject.stub(:exists?).and_return true
      end

      it 'runs the command and updates observers' do
        shell.should_receive(:exec).with 'rm -rf /file'
        subject.should_receive(:changed)
        subject.should_receive(:notify_observers).
          with(subject, attribute: :path, old: '/file', new: nil,
          as_sudo: false)

        subject.delete
      end
    end

    context 'command failed' do
      before do
        shell.stub(:last_exit_status).and_return 1
      end

      it 'runs the command but does not update observers' do
        shell.should_receive(:exec).with 'rm -rf /file'
        subject.should_not_receive(:changed)
        subject.should_not_receive(:notify_observers)

        subject.delete
      end
    end
  end
end
