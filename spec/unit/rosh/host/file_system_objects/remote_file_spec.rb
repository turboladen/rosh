require 'spec_helper'
require 'rosh/host/adapters/remote_file'


describe Rosh::Host::FileSystemObjects::RemoteFile do
  subject do
    Rosh::Host::FileSystemObjects::RemoteFile.new(path, 'test_host')
  end

  let(:path) { '/file' }
  let(:shell) { double 'Rosh::Host::Shells::Remote', :su? => false }
  before { allow(subject).to receive(:current_shell) { shell } }

  describe '#contents' do
    context 'file does not exist' do
      context 'no in-memory contents' do
        before do
          expect(shell).to receive(:cat) do
            'cat: blah: No such file or directory'
          end

          expect(shell).to receive(:last_exit_status) { 1 }
        end

        specify { expect(subject.contents).to be_nil }
      end

      context 'no in-memory contents' do
        before { subject.instance_variable_set(:@unwritten_contents, '12345') }
        specify { expect(subject.contents).to eq '12345' }
      end
    end

    context 'file exists' do
      before do
        expect(shell).to receive(:cat) { 'file contents' }
        expect(shell).to receive(:last_exit_status) { 0 }
      end

      it 'cats the remote file and returns that' do
        subject.contents.should == 'file contents'
      end
    end
  end

  describe '#contents=' do
    context 'check_state_first? is true' do
      before do
        shell.stub(:check_state_first?).and_return true
      end

      context 'contents differ' do
        before { subject.stub(:contents).and_return 'blskdjflksdjf' }

        it 'puts the contents in memory' do
          subject.contents = 'file contents'
          subject.instance_variable_get(:@unwritten_contents).
            should == 'file contents'
        end
      end

      context 'contents match' do
        before { subject.stub(:contents).and_return 'file contents' }

        it 'puts the contents in memory' do
          subject.contents = 'file contents'
          subject.instance_variable_get(:@unwritten_contents).should be_nil
        end
      end
    end

    context 'check_state_first? is false' do
      before do
        shell.stub(:check_state_first?).and_return false
      end

      it 'puts the contents in memory' do
        subject.contents = 'file contents'
        subject.instance_variable_get(:@unwritten_contents).
          should == 'file contents'
      end
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

    context 'check_state_first is true' do
      before do
        shell.stub(:check_state_first?).and_return true
      end

      context 'contents are the same as the rendered template' do
        before do
          subject.stub(:contents).and_return "var: hello!\n"
        end

        it 'returns nil' do
          subject.from_template('test', var: 'hello!')
          subject.instance_variable_get(:@unwritten_contents).should be_nil
        end
      end

      context 'contents differ from the rendered template' do
        before do
          subject.stub(:contents).and_return "var: hi!\n"
        end

        it 'renders the template and stores it in memory' do
          subject.from_template('test', var: 'hello!')
          subject.instance_variable_get(:@unwritten_contents).should == "var: hello!\n"
        end
      end
    end

    context 'check_state_first is false' do
      before do
        shell.stub(:check_state_first?).and_return false
      end

      it 'renders the template and stores it in memory' do
        subject.from_template('test', var: 'hello!')
        subject.instance_variable_get(:@unwritten_contents).should == "var: hello!\n"
      end
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
    context 'check_state_first? is true' do
      before { shell.stub(:check_state_first?).and_return true }

      context 'file already exists' do
        before do
          subject.stub(:exists?).and_return true
          shell.should_not_receive(:exec)
        end

        it 'returns nil' do
          subject.send(:create).should be_nil
        end
      end

      context 'file does not exist' do
        before do
          subject.stub(:exists?).and_return false
          shell.should_receive(:exec).with('touch /file')
        end

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
              with(subject, attribute: :path, old: nil, new: '/file', as_sudo: false)
            subject.send(:create)
          end

          specify { subject.send(:create).should == true }
        end
      end
    end

    context 'check_state_first? is false' do
      before do
        shell.should_receive(:exec).with('touch /file')
        shell.stub(:check_state_first?).and_return true
        subject.stub(:exists?).and_return false
      end

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
            with(subject, attribute: :path, old: nil, new: '/file', as_sudo: false)
          subject.send(:create)
        end

        specify { subject.send(:create).should == true }
      end
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
          new: 'new contents', as_sudo: false)

        subject.send(:upload_new_content)
      end
    end
  end
end
