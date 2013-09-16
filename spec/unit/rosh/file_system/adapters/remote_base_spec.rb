require 'spec_helper'
require 'rosh/host/adapters/remote_base'


describe Rosh::Host::FileSystemObjects::RemoteBase do
  subject do
    Rosh::Host::FileSystemObjects::RemoteBase.new(path, 'test_host')
  end

  let(:path) { '/file' }
  let(:shell) { double 'Rosh::Host::Shells::Remote', :su? => false }
  before { allow(subject).to receive(:current_shell) { shell } }

  describe '.create' do
    before do
      Rosh::Host::FileSystemObjects::RemoteBase.should_receive(:new).
        and_return fso
    end

    context 'path is a directory' do
      let(:fso) do
        f = double 'Rosh::Host::FileSystemObjects::RemoteDir'
        f.should_receive(:directory?).and_return true

        f
      end

      it 'returns a new Rosh::Host::FileSystemObjects::RemoteDir' do
        Rosh::Host::FileSystemObjects::RemoteDir.should_receive(:new).
          with('dir', shell).and_return 'the dir'
        Rosh::Host::FileSystemObjects::RemoteBase.create('dir', shell).
          should eq 'the dir'
      end
    end

    context 'path is a file' do
      let(:fso) do
        f = double 'Rosh::Host::FileSystemObjects::RemoteFile'
        f.should_receive(:directory?).and_return false
        f.should_receive(:file?).and_return true

        f
      end

      it 'returns a new Rosh::Host::FileSystemObjects::RemoteFile' do
        Rosh::Host::FileSystemObjects::RemoteFile.should_receive(:new).
          with('file', shell).and_return 'the file'
        Rosh::Host::FileSystemObjects::RemoteBase.create('file', shell).
          should eq 'the file'
      end
    end

    context 'path is a link' do
      let(:fso) do
        f = double 'Rosh::Host::FileSystemObjects::RemoteLink'
        f.should_receive(:directory?).and_return false
        f.should_receive(:file?).and_return false
        f.should_receive(:link?).and_return true

        f
      end

      it 'returns a new Rosh::Host::FileSystemObjects::RemoteLink' do
        Rosh::Host::FileSystemObjects::RemoteLink.should_receive(:new).
          with('link', shell).and_return 'the link'
        Rosh::Host::FileSystemObjects::RemoteBase.create('link', shell).
          should eq 'the link'
      end
    end
  end

  describe '#to_path' do
    it 'returns the path that the object was created with' do
      subject.to_path.should == path
    end
  end

  describe '#file?' do
    context 'command exit status is not 0' do
      before do
        shell.stub(:last_exit_status).and_return 1
      end

      it 'returns false' do
        shell.should_receive(:exec).with '[ -f /file ]'

        subject.file?.should be_false
      end
    end

    context 'command exit status is 0' do
      before do
        shell.stub(:last_exit_status).and_return 0
      end

      it 'returns true' do
        shell.should_receive(:exec).with '[ -f /file ]'

        subject.file?.should be_true
      end
    end
  end

  describe '#directory?' do
    context 'command exit status is not 0' do
      before do
        shell.stub(:last_exit_status).and_return 1
      end

      it 'returns false' do
        shell.should_receive(:exec).with '[ -d /file ]'

        subject.directory?.should be_false
      end
    end

    context 'command exit status is 0' do
      before do
        shell.stub(:last_exit_status).and_return 0
      end

      it 'returns true' do
        shell.should_receive(:exec).with '[ -d /file ]'

        subject.directory?.should be_true
      end
    end
  end

  describe '#link?' do
    context 'command exit status is not 0' do
      before do
        shell.stub(:last_exit_status).and_return 1
      end

      it 'returns false' do
        shell.should_receive(:exec).with '[ -L /file ]'

        subject.link?.should be_false
      end
    end

    context 'command exit status is 0' do
      before do
        shell.stub(:last_exit_status).and_return 0
      end

      it 'returns true' do
        shell.should_receive(:exec).with '[ -L /file ]'

        subject.link?.should be_true
      end
    end
  end

  describe '#exists?' do
    context 'command exit status is not 0' do
      before do
        shell.stub(:last_exit_status).and_return 1
      end

      it 'returns false' do
        shell.should_receive(:exec).with '[ -e /file ]'

        subject.exists?.should be_false
      end
    end

    context 'command exit status is 0' do
      before do
        shell.stub(:last_exit_status).and_return 0
      end

      it 'returns true' do
        shell.should_receive(:exec).with '[ -e /file ]'

        subject.exists?.should be_true
      end
    end
  end

  describe '#owner' do
    context 'command output is empty' do
      it 'returns an empty string' do
        shell.should_receive(:exec).with("ls -l /file | awk '{print $3}'").
          and_return('')

        subject.owner.should == ''
      end
    end

    context 'command output contains the owner' do
      it 'returns the owner' do
        shell.should_receive(:exec).with("ls -l /file | awk '{print $3}'").
          and_return("person\r\n")

        subject.owner.should == 'person'
      end
    end
  end

  describe '#owner=' do
    before do
      subject.stub(:owner).and_return 'person'
      shell.stub(:last_exit_status).and_return 0
      shell.stub(:check_state_first?).and_return false
    end

    context 'new_owner is the same as the old owner' do
      context 'check state first' do
        before do
          shell.stub(:check_state_first?).and_return true
        end

        it 'does not run the command' do
          shell.should_not_receive(:exec).with 'chown person /file'
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.owner = 'person'
        end
      end

      context 'do not check state first' do
        it 'runs the command but does not update observers' do
          shell.should_receive(:exec).with 'chown person /file'
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.owner = 'person'
        end
      end
    end

    context 'new_owner is not the same as the old owner' do
      it 'runs the command and updates observers' do
        shell.should_receive(:exec).with 'chown someone /file'
        subject.should_receive(:changed)
        subject.should_receive(:notify_observers).
          with(subject, attribute: :owner, old: 'person', new: 'someone',
          as_sudo: false)

        subject.owner = 'someone'
      end
    end

    context 'command failed' do
      before do
        shell.stub(:last_exit_status).and_return 1
      end

      it 'runs the command but does not update observers' do
        shell.should_receive(:exec).with 'chown someone /file'
        subject.should_not_receive(:changed)
        subject.should_not_receive(:notify_observers)

        subject.owner = 'someone'
      end
    end
  end

  describe '#group' do
    context 'command output is empty' do
      it 'returns an empty string' do
        shell.should_receive(:exec).with("ls -l /file | awk '{print $4}'").
          and_return('')

        subject.group.should == ''
      end
    end

    context 'command output contains the group' do
      it 'returns the group' do
        shell.should_receive(:exec).with("ls -l /file | awk '{print $4}'").
          and_return("people\r\n")

        subject.group.should == 'people'
      end
    end
  end

  describe '#group=' do
    before do
      subject.stub(:group).and_return 'people'
      shell.stub(:last_exit_status).and_return 0
      shell.stub(:check_state_first?).and_return false
    end

    context 'new_group is the same as the old group' do
      context 'check state first' do
        before do
          shell.stub(:check_state_first?).and_return true
        end

        it 'does not run the command' do
          shell.should_not_receive(:exec).with 'chgrp people /file'
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.group = 'people'
        end
      end

      context 'do not check state first' do
        it 'runs the command but does not update observers' do
          shell.should_receive(:exec).with 'chgrp people /file'
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.group = 'people'
        end
      end
    end

    context 'new_group is not the same as the old group' do
      it 'runs the command and updates observers' do
        shell.should_receive(:exec).with 'chgrp strangers /file'
        subject.should_receive(:changed)
        subject.should_receive(:notify_observers).
          with(subject, attribute: :group, old: 'people', new: 'strangers',
          as_sudo: false)

        subject.group = 'strangers'
      end
    end

    context 'command failed' do
      before do
        shell.stub(:last_exit_status).and_return 1
      end

      it 'runs the command but does not update observers' do
        shell.should_receive(:exec).with 'chgrp strangers /file'
        subject.should_not_receive(:changed)
        subject.should_not_receive(:notify_observers)

        subject.group = 'strangers'
      end
    end
  end

  describe '#mode' do
    it 'gets the letter mode and passes that to #mode_to_i' do
      shell.should_receive(:exec).with("ls -l /file | awk '{print $1}'").
        and_return 'rwx'
      subject.should_receive(:mode_to_i).with('rwx')

      subject.mode
    end
  end

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

  describe '#basename' do
    it 'returns the base name of the object' do
      subject.basename.should eq 'file'
    end
  end

  describe '#remove' do
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

          subject.remove
        end
      end

      context 'do not check state first' do
        it 'runs the command but does not update observers' do
          shell.should_receive(:exec).with 'rm -rf /file'
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.remove
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

        subject.remove
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

        subject.remove
      end
    end
  end

  describe '#mode_do_i' do
    context 'letter mode is empty string' do
      it 'returns an empty string' do
        subject.send(:mode_to_i, '').should == nil
      end
    end

    context 'letter mode contains valid leters' do
      it 'returns the mode' do
        subject.send(:mode_to_i, "-rwxrwxrwx\r\n").should == 777
      end
    end
  end
end
