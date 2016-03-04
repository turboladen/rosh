require 'rosh'

RSpec.shared_examples_for 'a file manager' do
  it 'can get the home directory' do
    expect(host.fs.home.to_s).to eq home_directory
    expect(host.fs.home).to be_a Rosh::FileSystem::Directory
    expect(host.fs.home.directory?).to eq true
  end

  # it 'can list files in a directory' do
  #   dir = host.fs['/etc']

  #   dir.list do |obj|
  #     expect(obj.class.name).to match(/Rosh::FileSystem/)
  #   end
  # end

  describe 'files' do
    it 'can create and delete a file' do
      if host.fs[file: file].exists?
        expect(host.fs[file: file].delete).to eq true
      end

      expect(host.fs[file: file].exists?).to eq false

      expect(host.fs[file: file].create).to eq true
      expect(host.fs[file].exists?).to eq true

      expect(host.fs[file: file].delete).to eq true
      expect(host.fs[file].exists?).to eq false
    end
  end

  describe 'directories' do
    it 'can create and delete a directory' do
      expect(host.fs[dir: dir].delete).to eq true if host.fs[dir: dir].exists?

      expect(host.fs[dir: dir].exists?).to eq false

      expect(host.fs[dir: dir].create).to eq true
      expect(host.fs[dir].exists?).to eq true

      expect(host.fs[dir: dir].delete).to eq true
      expect(host.fs[dir].exists?).to eq false
    end
  end

  describe 'symlinking' do
    before do
      if host.fs[symbolic_link: symlink].exists?
        host.fs[symbolic_link: symlink].delete
        expect(host.fs[symbolic_link: symlink].exists?).to eq false
      end

      host.fs[file: file].create
    end

    after do
      host.fs[symbolic_link: symlink].delete
      host.fs[file: file].delete
    end

    it 'can create and delete a symlink' do
      expect(host.fs[symbolic_link: symlink].link_to(file)).to eq true
      expect(host.fs[symbolic_link: symlink].exists?).to eq true

      dest = host.fs[symbolic_link: symlink].destination
      expect(dest).to be_a Rosh::FileSystem::File
      expect(dest.to_path).to eq file

      expect(host.fs[symbolic_link: symlink].delete).to eq true
      expect(host.fs[symbolic_link: symlink].exists?).to eq false
    end

    it 'returns a file object even if destination no longer exists' do
      expect(host.fs[symbolic_link: symlink].link_to(file)).to eq true
      expect(host.fs[symbolic_link: symlink].exists?).to eq true

      expect(host.fs[symbolic_link: symlink].destination.exists?).to eq true
      host.fs[file: file].delete

      expect(host.fs[symbolic_link: symlink].destination.exists?).to eq false
    end
  end
end

RSpec.describe 'File Management' do
  include_context 'hosts'
  let(:file) { '/tmp/rosh_test' }
  let(:dir) { '/tmp/rosh_test_dir' }
  let(:symlink) { '/tmp/rosh_test_symlink' }
  let(:home_directory) { '/home/vagrant' }

  # context 'centos' do
  #   it_behaves_like 'a file manager' do
  #     let(:host) { Rosh.hosts[:centos_57_64] }
  #   end
  # end

  # context 'debian' do
  #   it_behaves_like 'a file manager' do
  #     let(:host) { Rosh.hosts[:debian_squeeze_32] }
  #   end
  # end

  context 'localhost' do
    it_behaves_like 'a file manager' do
      let(:host) { Rosh.hosts['localhost'] }
      let(:home_directory) { Dir.home }
    end
  end
end
