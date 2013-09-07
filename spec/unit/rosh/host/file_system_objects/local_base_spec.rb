require 'spec_helper'
require 'rosh/host/adapters/local_base'


describe Rosh::Host::FileSystemObjects::LocalBase do
  subject { Rosh::Host::FileSystemObjects::LocalBase.new '/tmp' }

  describe '#owner' do
    let(:user) { double 'Struct::Passwd', uid: 123 }
    let(:group) { double 'Struct::Group', gid: 234 }

    before do
      Etc.stub(:getpwuid).and_return user
      Etc.stub(:getgrgid).and_return group
    end

    context 'no options given' do
      it 'returns the current user and group info' do
        subject.owner.should == {
          user: user,
          group: group
        }
      end
    end

    context 'options given' do
      before do
        subject.should_receive(:extract_uid).and_return 123
        subject.should_receive(:extract_gid).and_return 234
      end

      context 'chown succeeds' do
        it 'changes the ownership based on the given options' do
          subject.should_receive(:chown).with(123, 234).and_return 1

          subject.owner(user_name: 'user').should ==
            { user: user, group: group }
        end
      end

      context 'chown fails' do
        it 'raises with a message' do
          subject.should_receive(:chown).with(123, 234).and_return 100

          expect {
            subject.owner(user_name: 'user')
          }.to raise_error(RuntimeError, "Unable to chown using uid '123' and gid '234'.")
        end
      end
    end
  end

  describe '#to_path' do
    specify { subject.to_path.should == '/tmp' }
  end

  describe '#group' do
    let(:stat) { double 'File::Stat', gid: 123 }

    before do
      subject.stub(:stat).and_return stat
    end

    context 'group exists' do
      it 'returns the related Struct::Group' do
        Etc.should_receive(:getgrgid).with(123)

        subject.group
      end
    end

    context 'group does not exist' do
      it 'raises an ArgumentError' do
        expect { subject.group }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#to_s' do
    specify { subject.to_s.should == 'tmp' }
  end

  describe '#extract_uid' do
    context ':user_name given' do
      let(:user_name) { 'user' }
      let(:user) { double 'Struct::Passwd', uid: 123 }

      context ':user_name exists' do
        it 'returns the uid' do
          Etc.should_receive(:getpwnam).with(user_name).and_return user

          subject.send(:extract_uid, user_name: user_name).should == 123
        end
      end

      context ':user_name does not exist' do
        it 'raises an ArgumentError' do
          expect {
            subject.send(:extract_uid, user_name: user_name)
          }.to raise_error(ArgumentError)
        end
      end
    end

    context ':uid given' do
      context 'as a String' do
        specify { subject.send(:extract_uid, uid: '123').should == 123 }
      end

      context 'as a Fixnum' do
        specify { subject.send(:extract_uid, uid: 123).should == 123 }
      end
    end

    context 'neither :user_name nor :uid given' do
      specify { subject.send(:extract_uid, things: 'things').should be_nil }
    end
  end

  describe '#extract_gid' do
    context ':group_name given' do
      let(:group_name) { 'groupie' }
      let(:group) { double 'Struct::Group', gid: 123 }

      context ':group_name exists' do
        it 'returns the gid' do
          Etc.should_receive(:getgrnam).with(group_name).and_return group

          subject.send(:extract_gid, group_name: group_name).should == 123
        end
      end

      context ':group_name does not exist' do
        it 'raises an ArgumentError' do
          expect {
            subject.send(:extract_gid, group_name: group_name)
          }.to raise_error(ArgumentError)
        end
      end
    end

    context ':gid given' do
      context 'as a String' do
        specify { subject.send(:extract_gid, gid: '123').should == 123 }
      end

      context 'as a Fixnum' do
        specify { subject.send(:extract_gid, gid: 123).should == 123 }
      end
    end

    context 'neither :group_name nor :gid given' do
      specify { subject.send(:extract_gid, things: 'things').should be_nil }
    end
  end
end
