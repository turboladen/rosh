require 'spec_helper'
require 'rosh/host/package_types/deb'


describe Rosh::Host::PackageTypes::Deb do
  let(:shell) { double 'Rosh::Host::Shell', :su? => false }
  before { allow(subject).to receive(:current_shell) { shell } }
  subject { Rosh::Host::PackageTypes::Deb.new('thing', 'example.com') }

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
      it 'adds -version to the install command' do
        allow(shell).to receive(:last_exit_status) { 0 }
        expect(shell).to receive(:exec).
          with('DEBIAN_FRONTEND=noninteractive apt-get install thing=0.1.2 -y')

        subject.install('0.1.2')
      end
    end

    context 'no version' do
      before do
        expect(shell).to receive(:exec).
          with('DEBIAN_FRONTEND=noninteractive apt-get install thing -y')
      end

      context 'failed install' do
        before { allow(shell).to receive(:last_exit_status) { 1 } }
        specify { expect(subject.install).to eq false }
      end

      context 'successful install' do
        before { allow(shell).to receive(:last_exit_status) { 0 } }
        specify { expect(subject.install).to eq true }
      end
    end
  end

  describe '#installed?' do
    before { expect(shell).to receive(:exec).with('dpkg --status thing') }

    context 'not installed' do
      before { allow(shell).to receive(:last_exit_status) { 1 } }
      specify { expect(subject).to_not be_installed }
    end

    context 'installed' do
      before { allow(shell).to receive(:last_exit_status) { 0 } }
      specify { expect(subject).to be_installed }
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
      expect(shell).to receive(:exec).
        with('DEBIAN_FRONTEND=noninteractive apt-get remove thing')
    end

    context 'failed removal' do
      before { allow(shell).to receive(:last_exit_status) { 1 } }
      specify { expect(subject.remove).to eq false }
    end

    context 'successful removal' do
      before { allow(shell).to receive(:last_exit_status) { 0 } }
      specify { expect(subject.remove).to eq true }
    end
  end

  describe '#upgrade' do
    it 'calls #install' do
      subject.should_receive(:install)
      subject.upgrade
    end
  end
end
