require 'spec_helper'
require 'rosh/file_system/stat_methods'

describe Rosh::FileSystem::StatMethods do
  let(:fake_adapter) { double 'Adapter' }

  subject do
    o = Object.new.extend(described_class)
    o.stub(:adapter) { fake_adapter }

    o
  end

  it { should respond_to :<=> }
  it { should respond_to :blksize }
  it { should respond_to :blockdev? }
  it { should respond_to :blocks }
  it { should respond_to :chardev? }
  it { should respond_to :dev }
  it { should respond_to :dev_major }
  it { should respond_to :dev_minor }
  it { should respond_to :directory? }
  it { should respond_to :executable? }
  it { should respond_to :executable_real? }
  it { should respond_to :exists? }
  it { should respond_to :file? }
  it { should respond_to :gid }
  it { should respond_to :grpowned? }
  it { should respond_to :ino }
  it { should respond_to :mode }
  it { should respond_to :nlink }
  it { should respond_to :owned? }
  it { should respond_to :pipe? }
  it { should respond_to :rdev }
  it { should respond_to :rdev_major }
  it { should respond_to :rdev_minor }
  it { should respond_to :readable? }
  it { should respond_to :readable_real? }
  it { should respond_to :setgid? }
  it { should respond_to :size }
  it { should respond_to :socket? }
  it { should respond_to :sticky? }
  it { should respond_to :symlink? }
  it { should respond_to :uid }
  it { should respond_to :world_readable? }
  it { should respond_to :world_writable? }
  it { should respond_to :writable? }
  it { should respond_to :writable_real? }
  it { should respond_to :zero? }

  describe '#zero?' do
    it 'delegates to the adapter' do
      expect(fake_adapter).to receive :zero?
      subject.zero?
    end
  end
end
