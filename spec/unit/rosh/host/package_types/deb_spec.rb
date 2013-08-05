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
      context 'check_state_first? is true' do
        before do
          shell.stub(:check_state_first?).and_return true
          subject.stub(:installed?).and_return true
          subject.stub(:current_version).and_return '0.1.2'
        end

        context 'version already installed' do
          specify { subject.install(version: '0.1.2').should be_nil }
        end

        context 'version not already installed' do
          before do
            subject.stub_chain(:info, :[]).and_return '0.1.2'
            shell.should_receive(:last_exit_status).and_return 0
            shell.should_receive(:exec).
              with('DEBIAN_FRONTEND=noninteractive apt-get install thing=1.2.3 -y')
          end

          specify { subject.install(version: '1.2.3').should be_true }
        end
      end

      context 'check_state_first? is false' do
        before do
          shell.stub(:check_state_first?).and_return false
          subject.stub_chain(:info, :[]).and_return '0.1.2'
          shell.should_receive(:last_exit_status).and_return 0
        end

        context 'version already installed' do
          before do
            subject.stub(:installed?).and_return true
            subject.stub(:current_version).and_return '0.1.2'
            shell.should_receive(:exec).
              with('DEBIAN_FRONTEND=noninteractive apt-get install thing=0.1.2 -y')
          end

          specify { subject.install(version: '0.1.2').should be_true }
        end

        context 'version not already installed' do
          it 'passes the version to the command' do
            subject.should_receive(:installed?).and_return true
            shell.should_receive(:exec).
              with('DEBIAN_FRONTEND=noninteractive apt-get install thing=1.2.3 -y')

            subject.install(version: '1.2.3')
          end
        end
      end
    end

    context 'no version' do
      before do
        shell.stub(:check_state_first?).and_return false
        shell.should_receive(:exec).
          with('DEBIAN_FRONTEND=noninteractive apt-get install thing -y')
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

  describe '#at_latest_version?' do
    before { shell.should_receive(:exec).and_return result }

    context 'not a package' do
      let(:result) do
        <<-RESULT
N: Unable to locate package meow
        RESULT
      end

      specify { subject.at_latest_version?.should be_nil }
    end

    context 'not installed' do
      let(:result) do
        <<-RESULT
git:
  Installed: (none)
  Candidate: 1:1.7.9.5-1
  Version table:
     1:1.7.9.5-1 0
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages
        100 /var/lib/dpkg/status
        RESULT
      end

      specify { subject.at_latest_version?.should be_false }
    end

    context 'installed' do
      context 'not at latest' do
        let(:result) do
          <<-RESULT
apt:
  Installed: 0.8.16~exp12ubuntu10
  Candidate: 0.8.16~exp12ubuntu10.12
  Version table:
     0.8.16~exp12ubuntu10.12 0
        500 http://us.archive.ubuntu.com/ubuntu/ precise-updates/main amd64 Packages
     0.8.16~exp12ubuntu10.10 0
        500 http://security.ubuntu.com/ubuntu/ precise-security/main amd64 Packages
 *** 0.8.16~exp12ubuntu10 0
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages
        100 /var/lib/dpkg/status
          RESULT
        end

        specify { subject.at_latest_version?.should be_false }
      end

      context 'at latest' do
        let(:result) do
          <<-RESULT
curl:
  Installed: 7.22.0-3ubuntu4.2
  Candidate: 7.22.0-3ubuntu4.2
  Version table:
 *** 7.22.0-3ubuntu4.2 0
        500 http://us.archive.ubuntu.com/ubuntu/ precise-updates/main amd64 Packages
        500 http://security.ubuntu.com/ubuntu/ precise-security/main amd64 Packages
        100 /var/lib/dpkg/status
     7.22.0-3ubuntu4 0
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages
          RESULT
        end

        specify { subject.at_latest_version?.should be_true }
      end
    end
  end

  describe '#current_version' do
    before { shell.should_receive(:exec).and_return result }

    context 'when not installed' do
      let(:result) do
        <<-RESULT
git:
  Installed: (none)
  Candidate: 1:1.7.9.5-1
  Version table:
     1:1.7.9.5-1 0
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages
        100 /var/lib/dpkg/status
        RESULT
      end

      specify { subject.current_version.should be_nil }
    end

    context 'when installed' do
      context 'and not current' do
        let(:result) do
          <<-RESULT
apt:
  Installed: 0.8.16~exp12ubuntu10
  Candidate: 0.8.16~exp12ubuntu10.12
  Version table:
     0.8.16~exp12ubuntu10.12 0
        500 http://us.archive.ubuntu.com/ubuntu/ precise-updates/main amd64 Packages
     0.8.16~exp12ubuntu10.10 0
        500 http://security.ubuntu.com/ubuntu/ precise-security/main amd64 Packages
 *** 0.8.16~exp12ubuntu10 0
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages
        100 /var/lib/dpkg/status
          RESULT
        end

        specify { subject.current_version.should == '0.8.16~exp12ubuntu10' }
      end

      context 'and current' do
        let(:result) do
          <<-RESULT
curl:
  Installed: 7.22.0-3ubuntu4.2
  Candidate: 7.22.0-3ubuntu4.2
  Version table:
 *** 7.22.0-3ubuntu4.2 0
        500 http://us.archive.ubuntu.com/ubuntu/ precise-updates/main amd64 Packages
        500 http://security.ubuntu.com/ubuntu/ precise-security/main amd64 Packages
        100 /var/lib/dpkg/status
     7.22.0-3ubuntu4 0
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages
          RESULT
        end

      end
    end
  end

  describe '#remove' do
    before do
      shell.should_receive(:exec).
        with('DEBIAN_FRONTEND=noninteractive apt-get remove thing')
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
