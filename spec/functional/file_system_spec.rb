require 'spec_helper'
require 'rosh/file_system'


describe Rosh::FileSystem do
  describe '.create' do
    context 'on a file' do
      it 'returns a Rosh::FileSystem::File' do
        result = Rosh::FileSystem.create(__FILE__, 'localhost')
        expect(result).to be_a Rosh::FileSystem::File
      end
    end

    context 'on a directory' do
      it 'returns a Rosh::FileSystem::Directory' do
        result = Rosh::FileSystem.create(File.dirname(__FILE__), 'localhost')
        expect(result).to be_a Rosh::FileSystem::Directory
      end
    end
  end
end
