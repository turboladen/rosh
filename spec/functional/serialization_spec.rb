require 'spec_helper'
require 'rosh/shell'
require 'rosh/file_system/object_adapters/remote_base'


describe 'Serialization' do
  describe Rosh::Shell do
    subject do
      Rosh::Shell.new('example.com', user: 'bobo',
        keys: %w[some_key])
    end

    context 'YAML' do
      let(:yaml) do
        <<-SHELL
--- !ruby/object:Rosh::Shell
host_name: example.com
user: bobo
options:
  :keys:
  - some_key
        SHELL
      end

      it 'outputs YAML with' do
        subject.to_yaml.should == yaml
      end

      it 'imports to a Rosh::Shell' do
        new_shell = YAML.load(yaml)
        new_shell.should be_a Rosh::Shell
        new_shell.host_name.should eq 'example.com'
        new_shell.options[:keys].should == %w[some_key]
        new_shell.instance_variable_get(:@user).should eq 'bobo'
        new_shell.instance_variable_get(:@sudo).should eq false
      end
    end
  end

  describe Rosh::FileSystem::File do
    pending

    subject do
      Rosh::FileSystem::File.new(__FILE__, 'example.com')
    end

    before do
      allow(subject).to receive(:current_shell).and_return {
        Rosh::Shell.new('example.com', user: 'bobo')
      }
    end

    context 'YAML' do
      let(:yaml) do
        <<-FSO
--- !ruby/object:Rosh::FileSystem::File
path: #{__FILE__}
host_name: example.com
        FSO
      end

      it 'outputs YAML with' do
        subject.to_yaml.should == <<-FSO
--- !ruby/object:Rosh::FileSystem::File
path: #{__FILE__}
host_name: example.com
        FSO
      end

      it 'imports to a Rosh::FileSystem::File' do
        new_fso = YAML.load(yaml)
        new_fso.should be_a Rosh::FileSystem::File
        new_fso.to_path.should eq __FILE__
        new_fso.instance_variable_get(:@host_name).should eq 'example.com'
      end
    end
  end
end
