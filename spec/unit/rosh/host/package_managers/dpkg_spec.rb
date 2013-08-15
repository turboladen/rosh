require 'spec_helper'
require 'rosh/host/package_managers/dpkg'


describe Rosh::Host::PackageManagers::Dpkg do
  let(:shell) { double 'Rosh::Host::Shell' }
  before { subject.instance_variable_set(:@shell, shell) }

  subject do
    Rosh::Host::PackageManagers::Dpkg.new(shell)
  end

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
end
