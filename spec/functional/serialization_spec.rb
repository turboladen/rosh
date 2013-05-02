require 'spec_helper'
require 'rosh/host/remote_file_system_object'


describe 'Serialization' do
  describe 'remote file system object' do
    let(:fso) do
      shell = double 'Rosh::Host::Shell'
      Rosh::Host::RemoteFileSystemObject.new(__FILE__, shell)
    end

    context 'YAML' do
      let(:yaml) do
        <<-FSO
--- !ruby/object:Rosh::Host::RemoteFileSystemObject
path: #{__FILE__}
        FSO
      end

      it 'outputs YAML with' do
        fso.to_yaml.should == <<-FSO
--- !ruby/object:Rosh::Host::RemoteFileSystemObject
path: #{__FILE__}
        FSO
      end

      it 'imports to a Rosh::Host::RemoteFileSystemObject' do
        new_fso = YAML.load(yaml)
        new_fso.should be_a Rosh::Host::RemoteFileSystemObject
        new_fso.to_path.should eq __FILE__
      end
    end
  end
end
