require 'spec_helper'
require 'rosh/host/adapters/local_dir'
require 'tmpdir'


describe Rosh::Host::FileSystemObjects::LocalDir do
  let(:dir) do
     Dir.mktmpdir 'rosh_test'
  end

  before { at_exit { Dir.delete(dir) } }

  after do
    Dir.delete(dir)
  end

  subject { Rosh::Host::FileSystemObjects::LocalDir.new(dir) }

  describe '#absolute_path' do
    specify { subject.absolute_path.should == dir }
  end

  describe '#atime' do
    specify { subject.atime.should be_a Time }
  end

  describe '#basename' do
    specify { subject.basename.should match %r[rosh_test] }
  end

  describe '#blockdev?' do
    specify { subject.blockdev?.should be_false }
  end

  describe '#chardev?' do
    specify { subject.chardev?.should be_false }
  end

  describe '#chmod' do
    specify { subject.chmod(0777).should eq 1 }
  end

  describe '#chown' do
    specify { subject.chown(nil, 100).should eq 1 }
  end

  describe '#ctime' do
    specify { subject.ctime.should be_a Time }
  end

  describe '#delete' do
    specify { subject.should respond_to :delete }
  end

  describe '#unlink' do
    specify { subject.should respond_to :unlink }
  end

  describe '#directory?' do
    specify { subject.directory?.should be_true }
  end

  describe '#dirname' do
    specify { subject.dirname.should eq Dir.tmpdir }
  end

  describe '#executable?' do
    specify { subject.executable?.should be_true }
  end

  describe '#executable_real?' do
    specify { subject.executable_real?.should be_true }
  end

  describe '#exist?' do
    specify { subject.exist?.should be_true }
  end

  describe '#exists?' do
    specify { subject.exists?.should be_true }
  end

  describe '#expand_path' do
    specify { subject.expand_path.should eq dir }
  end

  describe '#extname' do
    specify { subject.extname.should eq '' }
  end

  describe '#file?' do
    specify { subject.file?.should be_false }
  end

  describe '#fnmatch' do
    specify { subject.fnmatch('*rosh_test*').should be_true }
  end

  describe '#fnmatch?' do
    specify { subject.fnmatch?('*ROSH_test*', File::FNM_CASEFOLD).should be_true }
  end

  describe '#ftype' do
    specify { subject.ftype.should eq 'directory' }
  end

  describe '#grpowned?' do
    specify { subject.grpowned?.should be_true }
  end

  describe '#identical?' do
    specify { subject.identical?(__FILE__).should be_false }
  end

  describe '#join' do
    it 'is not defined' do
      subject.should_not respond_to :join
    end
  end

  describe '#lchmod' do
    specify { subject.lchmod(0777).should eq 1 }
  end

  describe '#lchown' do
    specify { subject.lchown(nil, 100).should eq 1 }
  end

  describe '#link' do
    specify { subject.should respond_to :link }
  end

  describe '#lstat' do
    specify { subject.lstat.should be_a File::Stat }
  end

  describe '#mtime' do
    specify { subject.mtime.should be_a Time }
  end

  describe '#open' do
    specify { subject.open.should be_a Dir }
  end

  describe '#owned?' do
    specify { subject.owned?.should be_true }
  end

  describe '#path' do
    specify { subject.path.should eq dir }
  end

  describe '#pipe?' do
    specify { subject.pipe?.should be_false }
  end

  describe '#readable?' do
    specify { subject.readable?.should be_true }
  end

  describe '#readable_real?' do
    specify { subject.readable_real?.should be_true }
  end

  describe '#readlink' do
    specify { subject.should_not respond_to :readlink }
  end

  describe '#realdirpath' do
    specify { subject.realdirpath.should_not be_empty }
  end

  describe '#rename' do
    specify { subject.should respond_to :rename }
  end

  describe '#setgid?' do
    specify { subject.setgid?.should be_false }
  end

  describe '#setuid?' do
    specify { subject.setuid?.should be_false }
  end

  describe '#size' do
    specify { subject.size.should > 0 }
  end

  describe '#size?' do
    specify { subject.size?.should be_true }
  end

  describe '#socket?' do
    specify { subject.socket?.should be_false }
  end

  describe '#split' do
    specify { subject.split.size.should eq 2 }
  end

  describe '#stat' do
    specify { subject.stat.should be_a File::Stat }
  end

  describe '#sticky?' do
    specify { subject.sticky?.should be_false }
  end

  describe '#symlink' do
    let(:link) do
      Dir.tmpdir + '/test_link'
    end

    before do
      at_exit { FileUtils.rm_f link }
    end

    specify do
      expect {
        subject.symlink(link).should be_zero
      }.to_not raise_exception
    end
  end

  describe '#symlink?' do
    specify { subject.symlink?.should be_false }
  end

  describe '#truncate' do
    specify { subject.should_not respond_to :truncate }
  end

  describe '#umask' do
    specify { subject.should_not respond_to :umask }
  end

  describe '#utime' do
    specify { subject.utime(Time.now, Time.now).should eq 1 }
  end

  describe '#world_readable?' do
    specify { subject.world_readable?.should be_nil }
  end

  describe '#world_writable?' do
    specify { subject.world_writable?.should be_nil }
  end

  describe '#writable?' do
    specify { subject.writable?.should be_true }
  end

  describe '#writable_real?' do
    specify { subject.writable_real?.should be_true }
  end

  describe '#zero?' do
    specify { subject.zero?.should be_false }
  end

  describe '#entries' do
    it 'returns an Array of LocalDir objects' do
      subject.entries.should be_an Array
      subject.entries[0].should be_a Rosh::Host::FileSystemObjects::LocalDir
      subject.entries[1].should be_a Rosh::Host::FileSystemObjects::LocalDir
    end
  end

  describe '#each' do
    context 'block given' do
      it 'yields each entry' do
        subject.each do |entry|
          entry.should be_a Rosh::Host::FileSystemObjects::LocalDir
        end
      end
    end

    context 'block not given' do
      it 'returns an Enumerable' do
        subject.each.should be_a Enumerable
      end
    end
  end

  describe '#open' do
    it 'yields each non-Rosh entry to the block' do
      subject.open do |entry|
        entry.should be_a Dir
      end
    end
  end

  describe '#owner' do
    it 'returns a Hash of :user and :group' do
      subject.owner.should include :user, :group
      subject.owner[:user].should be_a Struct::Passwd
      subject.owner[:group].should be_a Struct::Group
    end

    context ':user_name' do
      it 'changes the user' do
        subject.owner user_name: Etc.getlogin
      end
    end

    context ':user_uid' do
      it 'changes the user' do
        subject.owner user_uid: Etc.getpwnam(Etc.getlogin).uid
      end
    end

    context ':group_name' do
      it 'changes the group' do
        subject.owner group_name: Etc.getgrgid(Etc.getpwnam(Etc.getlogin).gid).name
      end
    end

    context ':group_uid' do
      it 'changes the group' do
        subject.owner group_uid: Etc.getpwnam(Etc.getlogin).gid
      end
    end
  end

  describe '#group' do
    specify { subject.group.should be_a Struct::Group }
  end
end
