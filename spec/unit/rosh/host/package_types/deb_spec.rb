require 'spec_helper'
require 'rosh/host/package_types/deb'


describe Rosh::Host::PackageTypes::Deb do
  let(:shell) { double 'Rosh::Host::Shell', :su? => false }

  subject do
    Rosh::Host::PackageTypes::Deb.new('thing', shell)
  end

  describe '#info' do
    let(:output) do
      <<-OUTPUT
Package: zlib1g-dev
Status: install ok installed
Multi-Arch: same
Installed-Size: 388
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Architecture: amd64
Version: 1:1.2.3.4.dfsg-3ubuntu4
Depends: zlib1g (= 1:1.2.3.4.dfsg-3ubuntu4), libc6-dev | libc-dev
Description: compression library - development
 zlib is a library implementing the deflate compression method found
 in gzip and PKZIP.  This package includes the development support
 files.
Homepage: http://zlib.net/
      OUTPUT
    end

    before do
      shell.should_receive(:exec).with('dpkg --status thing').and_return output
    end

    it 'parses each field and value to a Hash' do
      subject.info.should == {
        package: 'zlib1g-dev',
        status: 'install ok installed',
        multi_arch: 'same',
        installed_size: '388',
        maintainer: 'Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>',
        architecture: 'amd64',
        version: '1:1.2.3.4.dfsg-3ubuntu4',
        depends: 'zlib1g (= 1:1.2.3.4.dfsg-3ubuntu4), libc6-dev | libc-dev',
        description: "compression library - development
zlib is a library implementing the deflate compression method found
in gzip and PKZIP.  This package includes the development support
files.",
        homepage: 'http://zlib.net/'
      }
    end
  end

  describe 'installed?' do
    context 'is not installed' do
      before do
        shell.should_receive(:exec).with('dpkg --status thing')
        shell.stub(:last_exit_status).and_return 1
      end

      specify { subject.should_not be_installed }
    end

    context 'is installed' do
      before do
        shell.should_receive(:exec).with('dpkg --status thing')
        shell.stub(:last_exit_status).and_return 0
      end

      specify { subject.should be_installed }
    end
  end

  describe '#install' do
    context 'with version' do
      it 'passes the version to the command' do
        subject.should_receive(:installed?).and_return true
        subject.stub_chain(:info, :[]).and_return '0.1.2'
        shell.should_receive(:exec).with('apt-get install thing=1.2.3')
        shell.should_receive(:last_exit_status).and_return 0

        subject.install(version: '1.2.3')
      end
    end

    context 'no version' do
      before do
        shell.should_receive(:exec).with('apt-get install thing')
      end

      context 'package was already installed and at latest version' do
        before do
          subject.stub_chain(:info, :[]).and_return '1.2.3'
          subject.should_receive(:installed?).and_return true
        end

        context 'failed install' do
          before { shell.stub(:last_exit_status).and_return 1 }
          specify { subject.install.should == false }

          it 'does not notify observers' do
            subject.should_not_receive(:changed)
            subject.should_not_receive(:notify_observers)

            subject.install
          end
        end

        context 'successful install' do
          before { shell.stub(:last_exit_status).and_return 0 }
          specify { subject.install.should == true }

          it 'does not notify observers' do
            subject.should_not_receive(:changed)
            subject.should_not_receive(:notify_observers)

            subject.install
          end
        end
      end

      context 'package was already installed but at older version' do
        before do
          subject.should_receive(:installed?).and_return true
          subject.stub_chain(:info, :[]).and_return '0.1.2', '1.2.3'
        end

        context 'failed install' do
          before { shell.stub(:last_exit_status).and_return 1 }
          specify { subject.install.should == false }

          it 'does not notify observers' do
            subject.should_not_receive(:changed)
            subject.should_not_receive(:notify_observers)

            subject.install
          end
        end

        context 'successful install' do
          before { shell.stub(:last_exit_status).and_return 0 }
          specify { subject.install.should == true }

          it 'notifies observers' do
            subject.should_receive(:changed)
            subject.should_receive(:notify_observers).
              with(subject, attribute: :version, old: '0.1.2', new: '1.2.3',
              as_sudo: false)

            subject.install
          end
        end
      end

      context 'package not yet installed' do
        before do
          subject.should_receive(:installed?).and_return false
          subject.stub_chain(:info, :[]).and_return '1.2.3'
        end

        context 'failed install' do
          before { shell.stub(:last_exit_status).and_return 1 }
          specify { subject.install.should == false }

          it 'does not notify observers' do
            subject.should_not_receive(:changed)
            subject.should_not_receive(:notify_observers)

            subject.install
          end
        end

        context 'successful install' do
          before do
            shell.stub(:last_exit_status).and_return 0
            subject.stub_chain(:info, :[]).and_return '1.2.3'
          end

          specify { subject.install.should == true }

          it 'notifies observers' do
            subject.should_receive(:changed)
            subject.should_receive(:notify_observers).
              with(subject, attribute: :version, old: nil, new: '1.2.3',
              as_sudo: false)

            subject.install
          end
        end
      end
    end
  end

  describe '#remove' do
    before do
      shell.should_receive(:exec).with('apt-get remove thing')
      subject.stub_chain(:info, :[]).and_return '1.2.3'
    end

    context 'package was already installed' do
      before do
        subject.should_receive(:installed?).and_return true
      end

      context 'failed removal' do
        before { shell.stub(:last_exit_status).and_return 1 }
        specify { subject.remove.should == false }

        it 'does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.remove
        end
      end

      context 'successful removal' do
        before { shell.stub(:last_exit_status).and_return 0 }
        specify { subject.remove.should == true }

        it 'notifies observers' do
          subject.should_receive(:changed)
          subject.should_receive(:notify_observers).
            with(subject, attribute: :version, old: '1.2.3', new: nil,
            as_sudo: false)

          subject.remove
        end
      end
    end

    context 'package not yet installed' do
      before do
        subject.should_receive(:installed?).and_return false
      end

      context 'failed removal' do
        before { shell.stub(:last_exit_status).and_return 1 }
        specify { subject.remove.should == false }

        it 'does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.remove
        end
      end

      context 'successful removal' do
        before do
          shell.stub(:last_exit_status).and_return 0
          subject.stub_chain(:info, :[]).and_return '1.2.3'
        end

        specify { subject.remove.should == true}

        it 'does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.remove
        end
      end
    end
  end

  describe '#upgrade' do
    it 'calls #install' do
      subject.should_receive(:install)
      subject.upgrade
    end
  end
end
