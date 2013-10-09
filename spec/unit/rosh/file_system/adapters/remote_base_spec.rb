require 'spec_helper'
require 'rosh/file_system/adapters/remote_base'


describe Rosh::FileSystem::Adapters::RemoteBase do
  subject do
    k = Class.new { include(Rosh::FileSystem::Adapters::RemoteBase) }
    k.instance_variable_set(:@path, path)
    k.instance_variable_set(:@host_name, host_name)

    k
  end

  let(:path) { '/file' }
  let(:host_name) { 'hostname' }
  let(:shell) { double 'Rosh::Host::Shells::Remote', :su? => false }
  before { allow(subject).to receive(:current_shell) { shell } }

  describe '#create' do
    before do
      allow(shell).to receive(:last_exit_status) { 0 }
    end

    context 'without a block' do
      it 'runs "touch" on the remote file' do
        expect(shell).to receive(:exec).with('touch /file')
        subject.create
      end
    end

    context 'with a block' do
      pending 'Implementation'
    end

    context 'shell exits with 0' do
      it 'returns true' do
        allow(shell).to receive(:exec)
        expect(shell).to receive(:last_exit_status) { 0 }

        expect(subject.create).to eq true
      end
    end

    context 'shell exits with non-zero' do
      it 'returns false' do
        allow(shell).to receive(:exec)
        expect(shell).to receive(:last_exit_status) { 1 }

        expect(subject.create).to eq false
      end
    end
  end

  describe '#absolute_path' do
    pending 'Implementation'
  end

  describe '#atime' do
    it 'delegates to RemoteStat' do
      stat = double 'Rosh::FileSystem::RemoteStat'
      expect(stat).to receive(:atime)
      expect(Rosh::FileSystem::RemoteStat).to receive(:stat).
        with('/file', 'hostname') { stat }

      subject.atime
    end
  end

  describe '#basename' do
    context 'with suffix' do
      it 'runs the "basename" command on the remote path' do
        expect(shell).to receive(:exec).with('basename /file suffix') { "/file\r\n" }

        expect(subject.basename('suffix')).to eq '/file'
      end
    end

    context 'without suffix' do
      it 'runs the "basename" command on the remote path' do
        expect(shell).to receive(:exec).with('basename /file') { "/file\r\n" }

        expect(subject.basename).to eq '/file'
      end
    end
  end

  describe '#chmod' do
    it 'runs chmod on the path' do
      allow(shell).to receive(:last_exit_status) { 0 }
      expect(shell).to receive(:exec).with('chmod 123 /file')
      subject.chmod(123)
    end

    context 'successful' do
      it 'returns true' do
        allow(shell).to receive(:exec)
        allow(shell).to receive(:last_exit_status) { 0 }

        expect(subject.chmod(123)).to eq true
      end
    end

    context 'unsuccessful' do
      it 'returns false' do
        allow(shell).to receive(:exec)
        allow(shell).to receive(:last_exit_status) { 1 }

        expect(subject.chmod(123)).to eq false
      end
    end
  end

  describe '#chown' do
    context 'no gid given' do
      it 'calls chown with only the uid' do
        expect(shell).to receive(:exec).with 'chown 123 /file'
        allow(shell).to receive(:last_exit_status) { 0 }
        subject.chown 123
      end
    end

    context 'gid given' do
      it 'calls chown with the uid and gid' do
        expect(shell).to receive(:exec).with 'chown 123:456 /file'
        allow(shell).to receive(:last_exit_status) { 0 }
        subject.chown 123, 456
      end
    end

    context 'successful' do
      before { expect(shell).to receive(:last_exit_status) { 0 } }

      it 'returns true' do
        allow(shell).to receive(:exec)
        expect(subject.chown(123)).to eq true
      end
    end

    context 'unsuccessful' do
      before { expect(shell).to receive(:last_exit_status) { 1 } }

      it 'returns false' do
        allow(shell).to receive(:exec)
        expect(subject.chown(123)).to eq false
      end
    end
  end

  describe '#delete' do
    context 'successful' do
      it 'returns true' do
        expect(shell).to receive(:exec).with 'rm /file'
        expect(shell).to receive(:last_exit_status) { 0 }
        expect(subject.delete).to eq true
      end
    end

    context 'unsuccessful' do
      it 'returns false' do
        expect(shell).to receive(:exec).with 'rm /file'
        expect(shell).to receive(:last_exit_status) { 1 }
        expect(subject.delete).to eq false
      end
    end
  end

  describe '#dirname' do
    it 'returns the directory part of the path' do
      expect(subject.dirname).to eq '/'
    end
  end

  describe '#expand_path' do
    context 'darwin' do
      it 'returns the full path' do
        pending 'Implementation'
      end
    end

    context 'not darwin' do
      before { subject.stub_chain(:current_host, :darwin?).and_return false }

      it 'returns the result of the readlink command' do
        expect(shell).to receive(:exec).with('readlink -f /file') { "stuff\r\n" }
        expect(subject.expand_path).to eq 'stuff'
      end
    end
  end

  describe 'ftype' do
    context 'darwin' do
      before { subject.stub_chain(:current_host, :darwin?).and_return true }

      context 'file' do
        it 'returns :regular_file' do
          expect(shell).to receive(:exec).with("stat -n -f '%HT' /file") { "Regular File\r\n"}
          expect(subject.ftype).to eq :regular_file
        end
      end

      context 'directory' do
        it 'returns :directory' do
          expect(shell).to receive(:exec).with("stat -n -f '%HT' /file") { "Directory\r\n"}
          expect(subject.ftype).to eq :directory
        end
      end

      context 'symbolic link' do
        it 'returns :symbolic_link' do
          expect(shell).to receive(:exec).with("stat -n -f '%HT' /file") { "Symbolic Link\r\n"}
          expect(subject.ftype).to eq :symbolic_link
        end
      end
    end

    context 'not darwin' do
      before { subject.stub_chain(:current_host, :darwin?).and_return false }

      context 'file' do
        it 'returns :regular_file' do
          expect(shell).to receive(:exec).with("stat -c '%F' /file") { "regular file\r\n"}
          expect(subject.ftype).to eq :regular_file
        end
      end

      context 'directory' do
        it 'returns :directory' do
          expect(shell).to receive(:exec).with("stat -c '%F' /file") { "directory\r\n"}
          expect(subject.ftype).to eq :directory
        end
      end

      context 'symbolic link' do
        it 'returns :symbolic_link' do
          expect(shell).to receive(:exec).with("stat -c '%F' /file") { "symbolic link\r\n"}
          expect(subject.ftype).to eq :symbolic_link
        end
      end
    end
  end

  describe '#lchmod' do
    it 'runs lchmod on the path' do
      allow(shell).to receive(:last_exit_status) { 0 }
      expect(shell).to receive(:exec).with('chmod -h 123 /file')
      subject.lchmod(123)
    end

    context 'successful' do
      it 'returns true' do
        allow(shell).to receive(:exec)
        allow(shell).to receive(:last_exit_status) { 0 }

        expect(subject.lchmod(123)).to eq true
      end
    end

    context 'unsuccessful' do
      it 'returns false' do
        allow(shell).to receive(:exec)
        allow(shell).to receive(:last_exit_status) { 1 }

        expect(subject.lchmod(123)).to eq false
      end
    end
  end

  describe '#lchown' do
    context 'no gid given' do
      it 'calls lchown with only the uid' do
        expect(shell).to receive(:exec).with 'chown -h 123 /file'
        allow(shell).to receive(:last_exit_status) { 0 }
        subject.lchown 123
      end
    end

    context 'gid given' do
      it 'calls lchown with the uid and gid' do
        expect(shell).to receive(:exec).with 'chown -h 123:456 /file'
        allow(shell).to receive(:last_exit_status) { 0 }
        subject.lchown 123, 456
      end
    end

    context 'successful' do
      before { expect(shell).to receive(:last_exit_status) { 0 } }

      it 'returns true' do
        allow(shell).to receive(:exec)
        expect(subject.lchown(123)).to eq true
      end
    end

    context 'unsuccessful' do
      before { expect(shell).to receive(:last_exit_status) { 1 } }

      it 'returns false' do
        allow(shell).to receive(:exec)
        expect(subject.lchown(123)).to eq false
      end
    end
  end

  describe '#link' do
    it 'links the files' do
      expect(shell).to receive(:exec).with 'ln /file new_file'
      expect(shell).to receive(:last_exit_status) { 0 }
      subject.link 'new_file'
    end

    context 'success' do
      before do
        allow(shell).to receive(:exec)
        allow(shell).to receive(:last_exit_status) { 0 }
      end

      it 'returns true' do
        expect(subject.link('new_file')).to eq true
      end
    end

    context 'fail' do
      before do
        allow(shell).to receive(:exec)
        allow(shell).to receive(:last_exit_status) { 1 }
      end

      it 'returns true' do
        expect(subject.link('new_file')).to eq false
      end
    end
  end

  describe '#mtime' do
    it 'gets mtime from a RemoteStat' do
      stat = double 'Rosh::FileSystem::RemoteStat', mtime: nil
      expect(Rosh::FileSystem::RemoteStat).to receive(:stat).
        with('/file', host_name) { stat }
      subject.mtime
    end
  end

  describe '#readlink' do
    it 'returns the output of the readlink command' do
      expect(shell).to receive(:exec).with('readlink /file') { "file\r\n" }
      expect(subject.readlink).to eq 'file'
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

=begin
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
=end

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
