require 'rosh/package_manager/manager_adapters/apt'

RSpec.describe Rosh::PackageManager::ManagerAdapters::Apt do
  subject { Object.new.extend(described_class) }

  describe '#installed_packages' do
    let(:output) do
      <<-OUTPUT
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                                         Version                                      Description
+++-============================================-============================================-========================================================================================================
ii  accountsservice                              0.6.15-2ubuntu9.6                            query and manipulate user account information
ii  adduser                                      3.113ubuntu2                                 add and remove users and groups
ii  apparmor                                     2.7.102-0ubuntu3.7                           User-space parser utility for AppArmor
      OUTPUT
    end

    before do
      shell.should_receive(:exec).with('dpkg --list').and_return output
    end

    it 'creates a Deb package object for each package listed' do
      subject.should_receive(:create_package).
        with('accountsservice', version: '0.6.15-2ubuntu9.6', status: 'ii').
        and_return 'first package'
      subject.should_receive(:create_package).
        with('adduser', version: '3.113ubuntu2', status: 'ii').
        and_return 'second package'
      subject.should_receive(:create_package).
        with('apparmor', version: '2.7.102-0ubuntu3.7', status: 'ii').
        and_return 'third package'

      packages = subject.installed_packages
      packages.should be_an Array
      packages.size.should == 3
    end
  end

  describe '#update_definitions_command' do
    specify { expect(subject.update_definitions_command).to eq 'apt-get update' }
  end

  describe '#extract_update_definitions' do
    context 'index does not change during update' do
      let(:output) do
        <<-OUTPUT
Hit http://us.archive.ubuntu.com precise Release.gpg
Hit http://us.archive.ubuntu.com precise-updates Release.gpg
Hit http://us.archive.ubuntu.com precise-backports Release.gpg
Hit http://security.ubuntu.com precise-security Release.gpg
Hit http://us.archive.ubuntu.com precise Release
Hit http://us.archive.ubuntu.com precise-updates Release
Hit http://security.ubuntu.com precise-security Release
Hit http://us.archive.ubuntu.com precise-backports Release
Reading package lists... Done
        OUTPUT
      end

      it 'returns an empty Array' do
        expect(subject.send(:extract_updated_definitions, output)).to eq []
      end
    end

    context 'index changes after update' do
      let(:output) do
        <<-OUTPUT
Hit http://us.archive.ubuntu.com precise Release.gpg
Hit http://us.archive.ubuntu.com precise-updates Release.gpg
Get:1 http://us.archive.ubuntu.com precise-backports Release.gpg [198 B]
Hit http://security.ubuntu.com precise-security Release.gpg
Hit http://us.archive.ubuntu.com precise Release
Hit http://us.archive.ubuntu.com precise-updates Release
Hit http://security.ubuntu.com precise-security Release
Get:2 http://us.archive.ubuntu.com precise-backports Release [49.6 kB]
Fetched 163 kB in 1s (94.4 kB/s)
Reading package lists... Done
        OUTPUT
      end

      it 'returns an Array of Hashes containing the updated package defs' do
        expect(subject.send(:extract_updated_definitions, output)).to eq [
          {
            source: 'http://us.archive.ubuntu.com',
            distribution: 'precise-backports',
            components: %w[Release.gpg],
            size: '198 B'
          }, {
            source: 'http://us.archive.ubuntu.com',
            distribution: 'precise-backports',
            components: %w[Release],
            size: '49.6 kB'
          }
        ]
      end
    end
  end

  describe '#upgrade_packages_command' do
    specify do
      expect(subject.upgrade_packages_command).
        to eq 'apt-get upgrade -y DEBIAN_FRONTEND=noninteractive'
    end
  end

  describe '#extract_upgraded_packages' do
    let(:output) do
      <<-EOF
The following packages will be upgraded:
  accountsservice apparmor
  base-files bash
4 upgraded, 0 newly installed, 0 to remove and 3 not upgraded.
      EOF
    end

    it 'returns an array of new Deb packages' do
      result = subject.send(:extract_upgraded_packages, output)
      result.all? { |r| expect(r).to be_a Rosh::Host::Package }
    end
  end
end
