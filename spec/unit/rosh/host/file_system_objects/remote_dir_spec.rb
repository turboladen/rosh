require 'spec_helper'
require 'rosh/host/file_system_objects/remote_dir'


describe Rosh::Host::FileSystemObjects::RemoteDir do
  subject do
    Rosh::Host::FileSystemObjects::RemoteDir.new(path, shell)
  end

  let(:path) { '/dir' }
  let(:shell) { double 'Rosh::Host::Shells::Remote', :su? => false }

  describe '#owner' do
    context 'command output is empty' do
      it 'returns an empty string' do
        shell.should_receive(:exec).with("ls -ld /dir | awk '{print $3}'").
          and_return('')

        subject.owner.should == ''
      end
    end

    context 'command output contains the owner' do
      it 'returns the owner' do
        shell.should_receive(:exec).with("ls -ld /dir | awk '{print $3}'").
          and_return("person\r\n")

        subject.owner.should == 'person'
      end
    end
  end

  describe '#group' do
    context 'command output is empty' do
      it 'returns an empty string' do
        shell.should_receive(:exec).with("ls -ld /dir | awk '{print $4}'").
          and_return('')

        subject.group.should == ''
      end
    end

    context 'command output contains the group' do
      it 'returns the group' do
        shell.should_receive(:exec).with("ls -ld /dir | awk '{print $4}'").
          and_return("people\r\n")

        subject.group.should == 'people'
      end
    end
  end

  describe '#mode' do
    it 'gets the letter mode and passes that to #mode_to_i' do
      shell.should_receive(:exec).with("ls -ld /dir | awk '{print $1}'").
        and_return 'rwx'
      subject.should_receive(:mode_to_i).with('rwx')

      subject.mode
    end
  end

  describe '#save' do
    context 'directory already exists' do
      before { subject.should_receive(:exists?).and_return true }
      specify { subject.save.should == true }
    end

    context 'directory does not yet exist' do
      before { subject.should_receive(:exists?).and_return false }

      context 'command fails' do
        before do
          shell.should_receive(:exec).with('mkdir -p /dir')
          shell.should_receive(:last_exit_status).and_return 1
        end

        it 'does not notify observers and returns false' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)
          subject.save.should == false
        end
      end

      context 'command succeeds' do
        before do
          shell.should_receive(:exec).with('mkdir -p /dir')
          shell.should_receive(:last_exit_status).and_return 0
        end

        it 'notifies observers and returns true' do
          subject.should_receive(:changed)
          subject.should_receive(:notify_observers).
            with(subject, attribute: :path, old: nil, new: '/dir',
            as_sudo: false)

          subject.save.should == true
        end
      end
    end
  end
end
