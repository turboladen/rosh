require 'spec_helper'
require 'rosh/host/package_types/deb'


describe Rosh::Host::PackageTypes::Deb do
  let(:shell) { double 'Rosh::Host::Shell', :su? => false }
  subject { Object.new.extend Rosh::Host::PackageTypes::Deb }

  before do
    allow(subject).to receive(:current_shell) { shell }
    subject.instance_variable_set(:@name, 'thing')
  end

  describe '#info' do
    let(:output) do
      <<-OUTPUT
Package: zlib1g-dev\r
Status: install ok installed\r
Multi-Arch: same\r
Installed-Size: 388\r
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>\r
Architecture: amd64\r
Version: 1:1.2.3.4.dfsg-3ubuntu4\r
Depends: zlib1g (= 1:1.2.3.4.dfsg-3ubuntu4), libc6-dev | libc-dev\r
Description: compression library - development\r
 zlib is a library implementing the deflate compression method found\r
 in gzip and PKZIP.  This package includes the development support\r
 files.\r
Homepage: http://zlib.net/\r
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
git:\r
  Installed: (none)\r
  Candidate: 1:1.7.9.5-1\r
  Version table:\r
     1:1.7.9.5-1 0\r
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages\r
        100 /var/lib/dpkg/status\r
        RESULT
      end

      specify { subject.at_latest_version?.should be_false }
    end

    context 'installed' do
      context 'not at latest' do
        let(:result) do
          <<-RESULT
apt:\r
  Installed: 0.8.16~exp12ubuntu10\r
  Candidate: 0.8.16~exp12ubuntu10.12\r
  Version table:\r
     0.8.16~exp12ubuntu10.12 0\r
        500 http://us.archive.ubuntu.com/ubuntu/ precise-updates/main amd64 Packages\r
     0.8.16~exp12ubuntu10.10 0\r
        500 http://security.ubuntu.com/ubuntu/ precise-security/main amd64 Packages\r
 *** 0.8.16~exp12ubuntu10 0\r
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages\r
        100 /var/lib/dpkg/status\r
          RESULT
        end

        specify { subject.at_latest_version?.should be_false }
      end

      context 'at latest' do
        let(:result) do
          <<-RESULT
curl:\r
  Installed: 7.22.0-3ubuntu4.2\r
  Candidate: 7.22.0-3ubuntu4.2\r
  Version table:\r
 *** 7.22.0-3ubuntu4.2 0\r
        500 http://us.archive.ubuntu.com/ubuntu/ precise-updates/main amd64 Packages\r
        500 http://security.ubuntu.com/ubuntu/ precise-security/main amd64 Packages\r
        100 /var/lib/dpkg/status\r
     7.22.0-3ubuntu4 0\r
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages\r
          RESULT
        end

        specify { subject.send(:at_latest_version?).should be_true }
      end
    end
  end

  describe '#current_version' do
    before { shell.should_receive(:exec).and_return result }

    context 'when not installed' do
      let(:result) do
        <<-RESULT
git:\r
  Installed: (none)\r
  Candidate: 1:1.7.9.5-1\r
  Version table:\r
     1:1.7.9.5-1 0\r
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages\r
        100 /var/lib/dpkg/status\r
        RESULT
      end

      specify { subject.current_version.should be_nil }
    end

    context 'when installed' do
      context 'and not current' do
        let(:result) do
          <<-RESULT
apt:\r
  Installed: 0.8.16~exp12ubuntu10\r
  Candidate: 0.8.16~exp12ubuntu10.12\r
  Version table:\r
     0.8.16~exp12ubuntu10.12 0\r
        500 http://us.archive.ubuntu.com/ubuntu/ precise-updates/main amd64 Packages\r
     0.8.16~exp12ubuntu10.10 0\r
        500 http://security.ubuntu.com/ubuntu/ precise-security/main amd64 Packages\r
 *** 0.8.16~exp12ubuntu10 0\r
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages\r
        100 /var/lib/dpkg/status\r
          RESULT
        end

        specify { subject.current_version.should == '0.8.16~exp12ubuntu10' }
      end

      context 'and current' do
        let(:result) do
          <<-RESULT
curl:\r
  Installed: 7.22.0-3ubuntu4.2\r
  Candidate: 7.22.0-3ubuntu4.2\r
  Version table:\r
 *** 7.22.0-3ubuntu4.2 0\r
        500 http://us.archive.ubuntu.com/ubuntu/ precise-updates/main amd64 Packages\r
        500 http://security.ubuntu.com/ubuntu/ precise-security/main amd64 Packages\r
        100 /var/lib/dpkg/status\r
     7.22.0-3ubuntu4 0\r
        500 http://us.archive.ubuntu.com/ubuntu/ precise/main amd64 Packages\r
          RESULT
        end
      end
    end
  end

  describe 'default_bin_path' do
    specify { expect(subject.send(:default_bin_path)).to eq '/usr/local' }
  end

  describe '#install_package' do
    context 'with version' do
      it 'adds -version to the install command' do
        allow(shell).to receive(:last_exit_status) { 0 }
        expect(shell).to receive(:exec).
          with('DEBIAN_FRONTEND=noninteractive apt-get install thing=0.1.2 -y')

        subject.send(:install_package, '0.1.2')
      end
    end

    context 'no version' do
      before do
        expect(shell).to receive(:exec).
          with('DEBIAN_FRONTEND=noninteractive apt-get install thing -y')
      end

      context 'failed install' do
        before { allow(shell).to receive(:last_exit_status) { 1 } }
        specify { expect(subject.send(:install_package)).to eq false }
      end

      context 'successful install' do
        before { allow(shell).to receive(:last_exit_status) { 0 } }
        specify { expect(subject.send(:install_package)).to eq true }
      end
    end
  end

  describe '#upgrade_package' do
    it 'calls #install_package' do
      subject.should_receive(:install_package)
      subject.send(:upgrade_package)
    end
  end

  describe '#remove_package' do
    before do
      expect(shell).to receive(:exec).
        with('DEBIAN_FRONTEND=noninteractive apt-get remove thing')
    end

    context 'failed removal' do
      before { allow(shell).to receive(:last_exit_status) { 1 } }
      specify { expect(subject.send(:remove_package)).to eq false }
    end

    context 'successful removal' do
      before { allow(shell).to receive(:last_exit_status) { 0 } }
      specify { expect(subject.send(:remove_package)).to eq true }
    end
  end
end
