require 'spec_helper'
require 'rosh'


shared_examples_for 'a shell' do
  it 'can list files in a directory' do
    list = host.shell.ls

    list.each do |obj|
      expect(obj.class.name).to match /Rosh::FileSystem/
    end
  end
end


describe 'Shell use' do
  include_context 'hosts'

  context 'localhost' do
    it_behaves_like 'a shell' do
      let(:host) { Rosh.hosts['localhost'] }
    end
  end

  context 'centos' do
    it_behaves_like 'a shell' do
      let(:host) { Rosh.hosts[:centos_57_64] }
    end
  end
end
