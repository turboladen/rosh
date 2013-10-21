require 'spec_helper'
require 'rosh/file_system'


describe Rosh::FileSystem do
  subject { Rosh::FileSystem.new('test_host')}

  let(:current_host) do
    double 'Host', local?: true
  end

  before do
    Rosh::FileSystem.any_instance.stub(:current_host) { current_host }
  end

  describe '#[]' do
    context 'path is a Hash' do
      context ':file' do
        it 'calls #file with the Hash value' do
          filename = 'the file'
          expect(subject).to receive(:file).with(filename)
          subject[file: filename]
        end
      end

      context ':dir' do
        it 'calls #directory with the Hash value' do
          filename = 'the dir'
          expect(subject).to receive(:directory).with(filename)
          subject[dir: filename]
        end
      end

      context ':directory' do
        it 'calls #directory with the Hash value' do
          filename = 'the dir'
          expect(subject).to receive(:directory).with(filename)
          subject[directory: filename]
        end
      end

      context 'some other hash key' do
        it 'raises' do
          expect { subject[meow: 'stuff'] }.to raise_error(RuntimeError)
        end
      end
    end

    context 'path is not a Hash' do
      context 'path is a file' do
        before { allow(subject).to receive(:file?) { true } }

        it 'calls #file with the path' do
          filename = 'the file'
          expect(subject).to receive(:file).with(filename)
          subject[filename]
        end
      end

      context 'path is a directory' do
        before do
          allow(subject).to receive(:file?) { false }
          allow(subject).to receive(:directory?) { true }
        end

        it 'calls #directory with the path' do
          filename = 'the dir'
          expect(subject).to receive(:directory).with(filename)
          subject[filename]
        end
      end

      context 'path is neither a file nor a directory' do
        before do
          allow(subject).to receive(:file?) { false }
          allow(subject).to receive(:directory?) { false }
        end

        it 'raises' do
          expect { subject['stuff'] }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
