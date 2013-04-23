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

    context 'in-memory contents that are the same as the existing contents' do
      let(:tempfile) do
        double 'Tempfile'
      end

      before do
        subject.instance_variable_set(:@unwritten_contents, 'file contents')
        subject.should_receive(:contents).and_return 'file contents'
        shell.should_receive(:last_exit_status).and_return 0
      end

      it 'writes the in-memory contents to a Tempfile and uploads that' do
        Tempfile.should_receive(:new).with('rosh_remote_file').
          and_return tempfile

        tempfile.should_receive(:write).with 'file contents'
        tempfile.should_receive(:rewind)
        shell.should_receive(:upload).with(tempfile, path)
        tempfile.should_receive(:unlink)

        subject.save.should be_true
      end

      it 'does not notify observers' do
        shell.stub(:upload)

        subject.should_not_receive(:changed)
        subject.should_not_receive(:notify_observers)

        subject.save
      end
    end

    context 'in-memory contents that are different from the existing contents' do
      let(:tempfile) do
        double 'Tempfile'
      end

      before do
        subject.instance_variable_set(:@unwritten_contents, 'new contents')
        subject.should_receive(:contents).and_return 'old contents'
        shell.should_receive(:last_exit_status).and_return 0
      end

      it 'writes the in-memory contents to a Tempfile and uploads that' do
        Tempfile.should_receive(:new).with('rosh_remote_file').
          and_return tempfile

        tempfile.should_receive(:write).with 'new contents'
        tempfile.should_receive(:rewind)
        shell.should_receive(:upload).with(tempfile, path)
        tempfile.should_receive(:unlink)

        subject.save.should be_true
      end

      it 'notifies observers' do
        shell.stub(:upload)

        subject.should_receive(:changed)
        subject.should_receive(:notify_observers).
          with(subject, attribute: :contents, old: 'old contents',
          new: 'new contents')

        subject.save
      end
    end
  end
end
