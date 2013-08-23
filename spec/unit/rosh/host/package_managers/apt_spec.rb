require 'spec_helper'
require 'rosh/host/package_managers/apt'


describe Rosh::Host::PackageManagers::Apt do
  let(:shell) do
    s = double 'Rosh::Host::Shell'
    s.stub_chain(:history, :last, :[], :zero?)
    s.stub(:su?).and_return false

    s
  end

  let(:observer) do
    o = double 'Observer'
    o.define_singleton_method(:update) do |one, two|
      #
    end

    o
  end

  subject { Object.new.extend(Rosh::Host::PackageManagers::Apt) }

  before do
    allow(subject).to receive(:current_shell) { shell }
  end

  describe '#_update_definitions' do
    it 'calls apt-get update' do
      expect(shell).to receive(:exec).with('apt-get update')
      subject._update_definitions
    end
  end

  describe '#_extract_update_definitions' do
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
        expect(subject._extract_updated_definitions(output)).to eq []
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
        expect(subject._extract_updated_definitions(output)).to eq [
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

  describe '#_upgrade_packages' do
    it 'runs apt-get upgrade -y' do
      shell.should_receive(:exec).
        with('apt-get upgrade -y DEBIAN_FRONTEND=noninteractive')
      subject._upgrade_packages
    end
  end

  describe '#_extract_upgraded_packages' do
    let(:output) do
       <<-EOF
The following packages will be upgraded:
  accountsservice apparmor
  base-files bash
4 upgraded, 0 newly installed, 0 to remove and 3 not upgraded.
      EOF
    end

    it 'returns an array of new Deb packages' do
      result = subject._extract_upgraded_packages(output)
      result.all? { |r| expect(r).to be_a Rosh::Host::Package }
    end
  end
end
