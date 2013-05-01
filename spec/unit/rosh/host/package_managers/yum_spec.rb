require 'spec_helper'
require 'rosh/host/package_managers/yum'


describe Rosh::Host::PackageManagers::Yum do
  let(:shell) { double 'Rosh::Host::Shell' }

  let(:observer) do
    o = double 'Observer'
    o.define_singleton_method(:update) do |one, two|
      #
    end

    o
  end

  before { subject.instance_variable_set(:@shell, shell) }

  subject do
    o = Object.new
    o.extend Rosh::Host::PackageManagers::Yum

    o
  end

  describe '#installed_packages' do
    let(:output) do
      <<-OUTPUT
Loaded plugins: fastestmirror
base                                             | 1.1 kB     00:00
extras                                           | 2.1 kB     00:00
updates                                          | 1.9 kB     00:00
updates/primary_db                               | 376 kB     00:00
Installed Packages
MAKEDEV.x86_64                           3.23-1.2              installed
NetworkManager.i386                      1:0.7.0-13.el5        installed
NetworkManager.x86_64                    1:0.7.0-13.el5        installed
NetworkManager-glib.i386                 1:0.7.0-13.el5        installed
NetworkManager-glib.x86_64               1:0.7.0-13.el5        installed
ORBit2.x86_64                            2.14.3-5.el5          installed
      OUTPUT
    end

    before do
      shell.should_receive(:exec).with('yum list').and_return output
    end

    it 'creates a Rpm package object for each package' do
      subject.should_receive(:create).
        with('MAKEDEV', architecture: 'x86_64',version: '3.23-1.2', status: 'installed')
      subject.should_receive(:create).
        with('NetworkManager', architecture: 'i386', version: '1:0.7.0-13.el5',
        status: 'installed')
      subject.should_receive(:create).
        with('NetworkManager', architecture: 'x86_64', version: '1:0.7.0-13.el5',
        status: 'installed')
      subject.should_receive(:create).
        with('NetworkManager-glib', architecture: 'i386', version: '1:0.7.0-13.el5',
        status: 'installed')
      subject.should_receive(:create).
        with('NetworkManager-glib', architecture: 'x86_64', version: '1:0.7.0-13.el5',
        status: 'installed')
      subject.should_receive(:create).
        with('ORBit2', architecture: 'x86_64',version: '2.14.3-5.el5',
        status: 'installed')

      subject.installed_packages
    end
  end

  describe '#upgrade_packages' do
    before do
      subject.stub(:installed_packages).and_return []
      shell.should_receive(:exec).with('yum update -y').and_return output
    end

    context 'no packages to upgrade' do
      let(:output) { 'some output' }

      before do
        subject.should_receive(:extract_upgradable_packages).and_return []
      end

      context 'successful command' do
        before do
          shell.should_receive(:last_exit_status).and_return 0
        end

        it 'returns true but does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.upgrade_packages.should == true
        end
      end

      context 'unsuccessful command' do
        before do
          shell.should_receive(:last_exit_status).and_return 1
        end

        it 'returns false and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.upgrade_packages.should == false
        end
      end
    end

    context 'packages to upgrade' do
      before do
        subject.should_receive(:extract_upgradable_packages).
          and_return %w[upgrade_me]
      end

      context 'successful command' do
        before do
          shell.should_receive(:last_exit_status).and_return 0
        end

        let(:brew_package) { double 'Rosh::Host::PackageTypes::Brew' }

        it 'returns true and notifies observers' do
          subject.should_receive(:create).and_return brew_package
          subject.should_receive(:changed)
          subject.should_receive(:notify_observers).
            with(subject, attribute: :installed_packages, old: [],
            new: [brew_package])

          subject.upgrade_packages.should == true
        end
      end

      context 'unsuccessful command' do
        before do
          shell.should_receive(:last_exit_status).and_return 1
        end

        it 'returns false and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.upgrade_packages.should == false
        end
      end
    end
  end

  describe '#extract_upgradable_packages' do
    context 'nothing to upgrade' do
      let(:output) do
        <<-EOF
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.spro.net
 * extras: mirror.fdcservers.net
 * updates: mirrors.lga7.us.voxel.net
Setting up Update Process
No Packages marked for Update
        EOF
      end

      it 'returns an empty array' do
        subject.send(:extract_upgradable_packages, output).should == []
      end
    end

    context 'packages to upgrade' do
      let(:output) do
        <<-OUTPUT
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: yum.phx.singlehop.com
 * extras: mirror.cisp.com
 * updates: mirror.cs.vt.edu
Setting up Update Process
Resolving Dependencies
--> Running transaction check
---> Package device-mapper-multipath.x86_64 0:0.4.7-54.el5_9.2 set to be updated
---> Package glibc.i686 0:2.5-107.el5_9.4 set to be updated
---> Package glibc.x86_64 0:2.5-107.el5_9.4 set to be updated
---> Package glibc-common.x86_64 0:2.5-107.el5_9.4 set to be updated
---> Package glibc-devel.x86_64 0:2.5-107.el5_9.4 set to be updated
---> Package glibc-headers.x86_64 0:2.5-107.el5_9.4 set to be updated
---> Package kernel.x86_64 0:2.6.18-348.4.1.el5 set to be installed
---> Package kernel-devel.x86_64 0:2.6.18-348.4.1.el5 set to be installed
---> Package kernel-headers.x86_64 0:2.6.18-348.4.1.el5 set to be updated
--> Finished Dependency Resolution

Dependencies Resolved

===========================================================================================================================================
 Package                                   Arch                     Version                                Repository                 Size
===========================================================================================================================================
Installing:
 kernel                                    x86_64                   2.6.18-348.4.1.el5                     updates                    22 M
 kernel-devel                              x86_64                   2.6.18-348.4.1.el5                     updates                   5.9 M
Updating:
 device-mapper-multipath                   x86_64                   0.4.7-54.el5_9.2                       updates                   3.0 M
 glibc                                     i686                     2.5-107.el5_9.4                        updates                   5.4 M
 glibc                                     x86_64                   2.5-107.el5_9.4                        updates                   4.8 M
 glibc-common                              x86_64                   2.5-107.el5_9.4                        updates                    16 M
 glibc-devel                               x86_64                   2.5-107.el5_9.4                        updates                   2.4 M
 glibc-headers                             x86_64                   2.5-107.el5_9.4                        updates                   601 k

Transaction Summary
===========================================================================================================================================
Install       2 Package(s)
Upgrade      10 Package(s)

Total download size: 63 M
Is this ok [y/N]: y
Downloading Packages:
(1/9): glibc-headers-2.5-107.el5_9.4.x86_64.rpm                                                                    | 601 kB     00:01
(2/9): kernel-headers-2.6.18-348.4.1.el5.x86_64.rpm                                                                | 1.5 MB     00:01
(3/9): glibc-devel-2.5-107.el5_9.4.x86_64.rpm                                                                      | 2.4 MB     00:02
(4/9): device-mapper-multipath-0.4.7-54.el5_9.2.x86_64.rpm                                                         | 3.0 MB     00:02
(5/9): glibc-2.5-107.el5_9.4.x86_64.rpm                                                                            | 4.8 MB     00:04
(6/9): glibc-2.5-107.el5_9.4.i686.rpm                                                                              | 5.4 MB     00:03
(7/9): kernel-devel-2.6.18-348.4.1.el5.x86_64.rpm                                                                 | 5.9 MB     00:03
(8/9): glibc-common-2.5-107.el5_9.4.x86_64.rpm                                                                    |  12 MB     00:35 ...
http://mirror.cs.vt.edu/pub/CentOS/5.9/updates/x86_64/RPMS/glibc-common-2.5-107.el5_9.4.x86_64.rpm: [Errno 4] Socket Error: timed out
Trying other mirror.
(8/9): glibc-common-2.5-107.el5_9.4.x86_64.rpm                                                                    |  16 MB     00:02
(9/9): kernel-2.6.18-348.4.1.el5.x86_64.rpm                                                                       |  22 MB     00:11
-------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                      859 kB/s |  63 MB     01:15
Running rpm_check_debug
Running Transaction Test
Finished Transaction Test
Transaction Test Succeeded
Running Transaction
  Updating       : glibc-common                                                                                                       1/22
  Updating       : glibc                                                                                                              2/22
  Updating       : kernel-headers                                                                                                     3/22
  Updating       : device-mapper-multipath                                                                                            5/22
  Updating       : glibc-headers                                                                                                      8/22
  Updating       : glibc-devel                                                                                                        9/22
  Installing     : kernel-devel                                                                                                      10/22
  Installing     : kernel                                                                                                            11/22
  Updating       : glibc                                                                                                             12/22
  Cleanup        : glibc-devel                                                                                                       13/22
  Cleanup        : glibc-common                                                                                                      14/22
  Cleanup        : device-mapper-multipath                                                                                           15/22
  Cleanup        : glibc                                                                                                             17/22
  Cleanup        : glibc                                                                                                             20/22
  Cleanup        : glibc-headers                                                                                                     21/22
  Cleanup        : kernel-headers                                                                                                    22/22

Installed:
  kernel.x86_64 0:2.6.18-348.4.1.el5                                kernel-devel.x86_64 0:2.6.18-348.4.1.el5

Updated:
  device-mapper-multipath.x86_64 0:0.4.7-54.el5_9.2     glibc.i686 0:2.5-107.el5_9.4             glibc.x86_64 0:2.5-107.el5_9.4
  glibc-common.x86_64 0:2.5-107.el5_9.4                 glibc-devel.x86_64 0:2.5-107.el5_9.4     glibc-headers.x86_64 0:2.5-107.el5_9.4
  kernel-headers.x86_64 0:2.6.18-348.4.1.el5

Complete!
        OUTPUT
      end

      it 'returns an array of new Brew packages' do
        subject.should_receive(:create).with('device-mapper-multipath',
          version: '0:0.4.7-54.el5_9.2', architecture: 'x86_64').and_return 1
        subject.should_receive(:create).with('glibc',
          version: '0:2.5-107.el5_9.4', architecture: 'i686').and_return 2
        subject.should_receive(:create).with('glibc',
          version: '0:2.5-107.el5_9.4', architecture: 'x86_64').and_return 3
        subject.should_receive(:create).with('glibc-common',
          version: '0:2.5-107.el5_9.4', architecture: 'x86_64').and_return 4
        subject.should_receive(:create).with('glibc-devel',
          version: '0:2.5-107.el5_9.4', architecture: 'x86_64').and_return 5
        subject.should_receive(:create).with('glibc-headers',
          version: '0:2.5-107.el5_9.4', architecture: 'x86_64').and_return 6
        subject.should_receive(:create).with('kernel',
          version: '0:2.6.18-348.4.1.el5', architecture: 'x86_64').and_return 7
        subject.should_receive(:create).with('kernel-devel',
          version: '0:2.6.18-348.4.1.el5', architecture: 'x86_64').and_return 8
        subject.should_receive(:create).with('kernel-headers',
          version: '0:2.6.18-348.4.1.el5', architecture: 'x86_64').and_return 9

        result = subject.send(:extract_upgradable_packages, output)
        result.should eq [1, 2, 3, 4, 5, 6, 7, 8, 9]
      end
    end
  end
end
