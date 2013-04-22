require 'spec_helper'
require 'rosh/host/remote_file'


describe Rosh::Host::RemoteFile do
  subject do
    Rosh::Host::RemoteFile.new(path, shell)
  end

  let(:path) { '/file' }
  let(:shell) { double 'Rosh::Host::Shells::Remote' }

  describe '#contents' do
    before do
      shell.should_receive(:cat).and_return 'file contents'
    end

    it 'cats the remote file and returns that' do
      subject.contents.should == 'file contents'
    end
  end

  describe '#contents=' do
    it 'puts the contents in memory' do
      subject.contents = 'file contents'
      subject.instance_variable_get(:@unwritten_contents).should == 'file contents'
    end
  end

  describe '#from_template' do
    let(:template) do
      <<-TEMPLATE
var: <%= var %>
      TEMPLATE
    end

    before do
      File.should_receive(:read).and_return(template)
    end

    it 'renders the template and stores it in memory' do
      subject.from_template('test', var: 'hello!')
      subject.instance_variable_get(:@unwritten_contents).should == "var: hello!\n"
    end
  end

  describe '#save' do
    context 'no in-memory contents' do
      it 'returns false' do
        subject.save.should be_false
      end
    end

    context 'in-memory contents' do
      let(:tempfile) do
        double 'Tempfile'
      end

      before do
        subject.instance_variable_set(:@unwritten_contents, 'file contents')
      end

      it 'writes the in-memory contents to a Tempfile and uploads that' do
        Tempfile.should_receive(:new).with('rosh_remote_file').
          and_return tempfile

        tempfile.should_receive(:write).with 'file contents'
        tempfile.should_receive(:rewind)
        shell.should_receive(:upload).with(tempfile, path)
        tempfile.should_receive(:unlink)
        shell.should_receive(:last_exit_status).and_return 0

        subject.save.should be_true
      end
    end
  end
end
