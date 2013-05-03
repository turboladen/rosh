require 'spec_helper'
require 'rosh/host/shells/remote'
require 'rosh/host/remote_file_system_object'


describe 'Serialization' do
  describe Rosh::Host::Shells::Remote do
    subject do
      Rosh::Host::Shells::Remote.new('example.com', user: 'bobo', keys: %w[some_key])
    end

    context 'YAML' do
      let(:yaml) do
        <<-SHELL
--- !ruby/object:Rosh::Host::Shells::Remote
hostname: example.com
user: bobo
options:
  :keys:
  - some_key
        SHELL
      end

      it 'outputs YAML with' do
        subject.to_yaml.should == yaml
      end

      it 'imports to a Rosh::Host::Shells::Remote' do
        new_shell = YAML.load(yaml)
        new_shell.should be_a Rosh::Host::Shells::Remote
        new_shell.hostname.should eq 'example.com'
        new_shell.instance_variable_get(:@user).should eq 'bobo'
      end
    end
  end

  describe Rosh::Host::Shells::Remote do
    subject do
      shell = Rosh::Host::Shells::Remote.new('example.com', user: 'bobo')
      Rosh::Host::RemoteFileSystemObject.new(__FILE__, shell)
    end

    context 'YAML' do
      let(:yaml) do
        <<-FSO
--- !ruby/object:Rosh::Host::RemoteFileSystemObject
path: #{__FILE__}
shell: !ruby/object:Rosh::Host::Shells::Remote
  hostname: example.com
  user: bobo
        FSO
      end

      it 'outputs YAML with' do
        subject.to_yaml.should == <<-FSO
--- !ruby/object:Rosh::Host::RemoteFileSystemObject
path: #{__FILE__}
shell: !ruby/object:Rosh::Host::Shells::Remote
  hostname: example.com
  user: bobo
  options: {}
        FSO
      end

      it 'imports to a Rosh::Host::RemoteFileSystemObject' do
        new_fso = YAML.load(yaml)
        new_fso.should be_a Rosh::Host::RemoteFileSystemObject
        new_fso.to_path.should eq __FILE__
        shell = new_fso.instance_variable_get(:@remote_shell)
        shell.hostname.should eq 'example.com'
        shell.instance_variable_get(:@user).should eq 'bobo'
      end
    end
  end
end
