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
    context 'file already exists' do
      before do
        subject.should_receive(:exists?).and_return true
        subject.instance_variable_set(:@unwritten_contents, 'stuff')
      end

      it 'does not create it' do
        subject.stub(:upload_new_content)
        subject.should_not_receive(:create)
        subject.save
      end

      context 'no in-memory contents' do
        before { subject.instance_variable_set(:@unwritten_contents, nil) }

        it 'does not upload the new content and returns true' do
          subject.should_not_receive(:upload_new_content)
          subject.save.should == true
        end
      end

      context 'in-memory contents succeed uploading' do
        it 'uploads the new content and returns true' do
          subject.should_receive(:upload_new_content).and_return true
          subject.save.should == true
        end
      end

      context 'in-memory contents fail uploading' do
        it 'uploads the new content and returns false' do
          subject.should_receive(:upload_new_content).and_return false
          subject.save.should == false
        end
      end
    end

    context 'file does not already exist' do
      before { subject.should_receive(:exists?).and_return false }

      context 'it fails to create the file' do
        before do
          subject.should_receive(:create).and_return false
          subject.instance_variable_set(:@unwritten_contents, 'stuff')
        end

        context 'no in-memory contents' do
          before { subject.instance_variable_set(:@unwritten_contents, nil) }

          it 'does not upload the new content and returns false' do
            subject.should_not_receive(:upload_new_content)
            subject.save.should == false
          end
        end

        context 'in-memory contents succeed uploading' do
          it 'uploads the new content and returns false' do
            subject.should_receive(:upload_new_content).and_return true
            subject.save.should == false
          end
        end

        context 'in-memory contents fail uploading' do
          it 'uploads the new content and returns false' do
            subject.should_receive(:upload_new_content).and_return false
            subject.save.should == false
          end
        end
      end

      context 'it succeeds creating the file' do
        before do
          subject.should_receive(:create).and_return true
        end

        it 'creates it and returns true' do
          subject.save
        end

        context 'no in-memory contents' do
          it 'does not upload the new content and returns true' do
            subject.should_not_receive(:upload_new_content)
            subject.save.should == true
          end
        end

        context 'in-memory contents succeed uploading' do
          before { subject.instance_variable_set(:@unwritten_contents, 'stuff') }

          it 'uploads the new content and returns true' do
            subject.should_receive(:upload_new_content).and_return true
            subject.save.should == true
          end
        end

        context 'in-memory contents fail uploading' do
          before { subject.instance_variable_set(:@unwritten_contents, 'stuff') }

          it 'uploads the new content and returns false' do
            subject.should_receive(:upload_new_content).and_return false
            subject.save.should == false
          end
        end
      end
    end
  end

  describe '#create' do
    before { shell.should_receive(:exec).with('touch /file') }

    context 'command failed' do
      before { shell.should_receive(:last_exit_status).and_return 1 }

      it 'does not update observers' do
        subject.should_not_receive(:changed)
        subject.should_not_receive(:notify_observers)
        subject.send(:create)
      end

      specify { subject.send(:create).should == false }
    end

    context 'command succeeded' do
      before { shell.should_receive(:last_exit_status).and_return 0 }

      it 'updates observers' do
        subject.should_receive(:changed)
        subject.should_receive(:notify_observers).
          with(subject, attribute: :exists, old: false, new: true)
        subject.send(:create)
      end

      specify { subject.send(:create).should == true }
    end
  end

  describe '#upload_new_content' do
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

        subject.send(:upload_new_content).should be_true
      end

      it 'does not notify observers' do
        shell.stub(:upload)

        subject.should_not_receive(:changed)
        subject.should_not_receive(:notify_observers)

        subject.send(:upload_new_content)
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

        subject.send(:upload_new_content).should be_true
      end

      it 'notifies observers' do
        shell.stub(:upload)

        subject.should_receive(:changed)
        subject.should_receive(:notify_observers).
          with(subject, attribute: :contents, old: 'old contents',
          new: 'new contents')

        subject.send(:upload_new_content)
      end
    end
  end
end
