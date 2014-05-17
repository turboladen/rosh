require 'spec_helper'
require 'rosh/file_system/remote_stat'


describe Rosh::FileSystem::RemoteStat do
  let(:host) { double 'Rosh::Host' }
  let(:shell) { double 'Rosh::Shell' }
  let(:path) { 'fake path' }

  describe 'class methods' do
    subject do
      klass = described_class
      allow(klass).to receive(:current_shell) { shell }
      allow(klass).to receive(:current_host) { host }

      klass
    end

    before do
      allow(subject).to receive(:run).and_yield
    end

    describe '.blockdev?' do
      before do
        expect(shell).to receive(:exec) { '[ -b fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.blockdev?(path, 'testhost')).to eq true }
    end

    describe '.chardev?' do
      before do
        expect(shell).to receive(:exec) { '[ -c fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.chardev?(path, 'testhost')).to eq true }
    end

    describe '.dev_major' do
      before do
        expect(shell).to receive(:exec) { "0\r\n"}
        expect(host).to receive(:darwin?)
      end

      specify { expect(subject.dev_major(path, 'testhost')).to eq 0 }
    end

    describe '.dev_minor' do
      before do
        expect(shell).to receive(:exec) { "0\r\n"}
        expect(host).to receive(:darwin?)
      end

      specify { expect(subject.dev_minor(path, 'testhost')).to eq 0 }
    end

    describe '.directory?' do
      before do
        expect(shell).to receive(:exec) { '[ -d fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.directory?(path, 'testhost')).to eq true }
    end

    describe '.executable?' do
      before do
        expect(shell).to receive(:exec) { '[ -x fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.directory?(path, 'testhost')).to eq true }
    end

    describe '.file?' do
      before do
        expect(shell).to receive(:exec) { '[ -f fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.file?(path, 'testhost')).to eq true }
    end

    describe '.grpowned?' do
      before do
        expect(shell).to receive(:exec) { '[ -G fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.grpowned?(path, 'testhost')).to eq true }
    end

    describe '.owned?' do
      before do
        expect(shell).to receive(:exec) { '[ -O fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.owned?(path, 'testhost')).to eq true }
    end

    describe '.pipe?' do
      before do
        expect(shell).to receive(:exec) { '[ -p fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.pipe?(path, 'testhost')).to eq true }
    end

    describe '.readable?' do
      before do
        expect(shell).to receive(:exec) { '[ -r fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.readable?(path, 'testhost')).to eq true }
    end

    describe '.setgid?' do
      before do
        expect(shell).to receive(:exec) { '[ -g fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.setgid?(path, 'testhost')).to eq true }
    end

    describe '.socket?' do
      before do
        expect(shell).to receive(:exec) { '[ -S fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.socket?(path, 'testhost')).to eq true }
    end

    describe '.sticky?' do
      before do
        expect(shell).to receive(:exec) { '[ -k fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.sticky?(path, 'testhost')).to eq true }
    end

    describe '.symlink?' do
      before do
        expect(shell).to receive(:exec) { '[ -L fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.symlink?(path, 'testhost')).to eq true }
    end

    describe '.writable?' do
      before do
        expect(shell).to receive(:exec) { '[ -w fake path ]'}
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      specify { expect(subject.symlink?(path, 'testhost')).to eq true }
    end

    describe '.zero?' do
      before do
        expect(shell).to receive(:exec) { '[ -s fake path ]'}
        expect(shell).to receive(:last_exit_status) { 1 }
      end

      specify { expect(subject.zero?(path, 'testhost')).to eq true }
    end
  end

  describe 'instance methods' do
    let(:result) do
      'dev: 16777217 ino: 4408160 mode: 100644 nlink: 1 uid: 501 gid: 20 ' +
        'rdev: 0 size: 1067 blksize: 4096 blocks: 8 atime: 1379742799 ' +
        'mtime: 1375936779 ctime: 1375936779'
    end

    before do
      described_class.any_instance.stub(:current_host) { host }
      allow(host).to receive(:darwin?) { false }
    end

    subject do
      described_class.new(result, 'test_host')
    end

    specify { expect(subject.dev).to eq '0x16777217' }
    specify { expect(subject.ino).to eq 4408160 }

    context 'darwin' do
      before { allow(host).to receive(:darwin?) { true } }
      specify { expect(subject.mode).to eq '100644' }
    end

    specify { expect(subject.mode).to eq '4003104' }
    specify { expect(subject.nlink).to eq 1 }
    specify { expect(subject.uid).to eq 501 }
    specify { expect(subject.gid).to eq 20 }
    specify { expect(subject.rdev).to eq '0x0' }
    specify { expect(subject.size).to eq 1067 }
    specify { expect(subject.blksize).to eq 4096 }
    specify { expect(subject.blocks).to eq 8 }
    specify { expect(subject.atime).to eq Time.at(1379742799) }
    specify { expect(subject.mtime).to eq Time.at(1379742799) }
    specify { expect(subject.ctime).to eq Time.at(1379742799) }
  end
end
