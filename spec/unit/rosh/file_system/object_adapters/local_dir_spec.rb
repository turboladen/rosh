require 'spec_helper'
require 'rosh/file_system/object_adapters/local_dir'
require 'tmpdir'


describe Rosh::FileSystem::ObjectAdapters::LocalDir do
  subject do
    k = described_class
    k.instance_variable_set(:@path, '/dir')

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
  it { should_not respond_to :join }
  it { should respond_to :lchmod }
  it { should respond_to :lchown }
  it { should respond_to :link }
  it { should respond_to :lstat }
  it { should respond_to :mtime }

  describe '#open' do
    specify {
      expect(Dir).to receive(:open).with('/dir')
      subject.path = '/dir'
      subject.open
    }
  end

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

  describe '#entries' do
    it 'it creates a new Rosh FileSystem object for each entry' do
      entries_list = %w[. .. one two]
      expect(Rosh::FileSystem).to receive(:create).with('/dir/one', 'test') { 1 }
      expect(Rosh::FileSystem).to receive(:create).with('/dir/two', 'test') { 2 }
      expect(Dir).to receive(:entries).with('/dir') { entries_list }

      entries = subject.entries('test')
      expect(entries).to be_an Array
      expect(entries.size).to eq 2
    end
  end

  describe '#mkdir' do
    specify {
      expect(Dir).to receive(:mkdir).with '/dir'
      subject.mkdir
    }
  end

  describe '#rmdir' do
    specify {
      expect(Dir).to receive(:rmdir).with '/dir'
      subject.rmdir
    }
  end
end
