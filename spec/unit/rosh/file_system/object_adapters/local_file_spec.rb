require 'rosh/file_system/object_adapters/local_file'

RSpec.describe Rosh::FileSystem::ObjectAdapters::LocalFile do
  subject do
    k = described_class
    k.instance_variable_set(:@path, 'file')

    k
  end

  it { should respond_to :absolute_path }
  it { should respond_to :atime }
  it { should respond_to :basename }
  it { should respond_to :blockdev? }
  it { should respond_to :chardev? }
  it { should respond_to :chmod }
  it { should respond_to :chown }
  it { should respond_to :ctime }
  it { should respond_to :delete }
  it { should respond_to :unlink }
  it { should respond_to :directory? }
  it { should respond_to :dirname }
  it { should respond_to :executable? }
  it { should respond_to :executable_real? }
  it { should respond_to :exists? }
  it { should respond_to :expand_path }
  it { should respond_to :extname }
  it { should respond_to :file? }
  it { should respond_to :fnmatch }
  it { should respond_to :fnmatch? }
  it { should respond_to :ftype }
  it { should respond_to :grpowned? }
  it { should respond_to :identical? }
  it { should respond_to :lchmod }
  it { should respond_to :lchown }
  it { should respond_to :link }
  it { should respond_to :lstat }
  it { should respond_to :mtime }
  it { should respond_to :owned? }
  it { should respond_to :path }
  it { should respond_to :pipe? }
  it { should respond_to :readable? }
  it { should respond_to :readable_real? }
  it { should respond_to :readlink }
  it { should respond_to :realdirpath }
  it { should respond_to :rename }
  it { should respond_to :setgid? }
  it { should respond_to :setuid? }
  it { should respond_to :size }
  it { should respond_to :socket? }
  it { should respond_to :split }
  it { should respond_to :stat }
  it { should respond_to :sticky? }
  it { should respond_to :symlink }
  it { should respond_to :symlink? }
  it { should respond_to :truncate }
  it { should respond_to :utime }
  it { should respond_to :world_readable? }
  it { should respond_to :world_writable? }
  it { should respond_to :writable? }
  it { should respond_to :writable_real? }
  it { should respond_to :zero? }

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
