require 'spec_helper'
require 'rosh/host/package_types/rpm'


describe Rosh::Host::PackageTypes::Rpm do
  let(:shell) { double 'Rosh::Host::Shell', :su? => false }
  subject { Object.new.extend Rosh::Host::PackageTypes::Rpm }

  before do
    allow(subject).to receive(:current_shell) { shell }
    subject.instance_variable_set(:@name, 'thing')
  end

  describe '#_info' do
    let(:output) do
      <<-OUTPUT
Available Packages
Name       : zsh
Arch       : x86_64
Version    : 4.2.6
Release    : 8.el5
Size       : 1.8 M
Repo       : base
Summary    : A powerful interactive shell
URL        : http://zsh.sunsite.dk/
License    : BSD
Description: The zsh shell is a command interpreter usable as an interactive login
           : shell and as a shell script command processor.  Zsh resembles the ksh
           : shell (the Korn shell), but includes many enhancements.  Zsh supports
           : command line editing, built-in spelling correction, programmable
           : command completion, shell functions (with autoloading), a history
           : mechanism, and more.
      OUTPUT
    end

    before do
      expect(shell).to receive(:exec).with('yum info thing') { output }
    end

    it 'parses each field and value to a Hash' do
      subject.send(:_info).should == {
        name: 'zsh',
        arch: 'x86_64',
        version: '4.2.6',
        release: '8.el5',
        size: '1.8 M',
        repo: 'base',
        summary: 'A powerful interactive shell',
        url: 'http://zsh.sunsite.dk/',
        license: 'BSD',
        description: 'The zsh shell is a command interpreter usable as an interactive login ' +
          'shell and as a shell script command processor.  Zsh resembles the ksh ' +
          'shell (the Korn shell), but includes many enhancements.  Zsh supports ' +
          'command line editing, built-in spelling correction, programmable ' +
          'command completion, shell functions (with autoloading), a history ' +
          'mechanism, and more.'
      }
    end
  end

  describe '#_install' do
    context 'with version' do
      it 'adds -version to the install command' do
        allow(shell).to receive(:last_exit_status) { 0 }
        expect(shell).to receive(:exec).with('yum install -y thing-0.1.2')

        subject.send(:_install, '0.1.2')
      end
    end

    context 'no version' do
      before { expect(shell).to receive(:exec).with('yum install -y thing') }

      context 'failed install' do
        before { allow(shell).to receive(:last_exit_status) { 1 } }
        specify { expect(subject.send(:_install)).to eq false }
      end

      context 'successful install' do
        before { allow(shell).to receive(:last_exit_status) { 0 } }
        specify { expect(subject.send(:_install)).to eq true }
      end
    end
  end

  describe '_installed?' do
    before { expect(shell).to receive(:exec).with('yum info thing') }

    context 'is not installed' do
      before { allow(shell).to receive(:last_exit_status) { 1 } }
      specify { expect(subject).to_not be__installed }
    end

    context 'is installed' do
      before { allow(shell).to receive(:last_exit_status) { 0 } }
      specify { expect(subject).to be__installed }
    end
  end

  describe '#_at_latest_version?' do
    before { allow(shell).to receive(:exec).and_return(result1, result2) }

    context 'not a package' do
      let(:result1) do
        <<-RESULT
Loaded plugins: fastestmirror
Error: No matching Packages to list
        RESULT
      end

      let(:result2) do
        <<-RESULT
Loaded plugins: fastestmirror
Error: No matching Packages to list
        RESULT
      end

      specify { expect(subject.send(:_at_latest_version?)).to be_nil }
    end

    context 'not installed' do
      let(:result1) do
        <<-RESULT
Loaded plugins: fastestmirror
Error: No matching Packages to list
        RESULT
      end

      let(:result2) do
        <<-RESULT
Loaded plugins: fastestmirror
Available Packages
Name       : zope
Arch       : x86_64
Version    : 2.10.9
Release    : 1.el5
Size       : 14 M
Repo       : epel
Summary    : Web application server for flexible content management applications
URL        : http://www.zope.org/
License    : ZPL
Description: Zope is an application server framework that enables developers to quickly
           : build web applications such as intranets, portals, and content management
           : systems.
           :
           : Zope, by default, will listen on port 8080.
        RESULT
      end

      specify { expect(subject).to_not be__at_latest_version }
    end

    context 'installed but not latest' do
      let(:result1) do
        <<-RESULT
Loaded plugins: fastestmirror
Updated Packages
curl.i386              7.15.5-17.el5_9                updates
curl.x86_64            7.15.5-17.el5_9                updates
        RESULT
      end

      let(:result2) {}
      specify { expect(subject).to_not be__at_latest_version }
    end

    context 'installed and latest' do
      let(:result1) do
        <<-RESULT
Loaded plugins: fastestmirror
Error: No matching Packages to list
        RESULT
      end

      let(:result2) do
        <<-RESULT
Loaded plugins: fastestmirror
Installed Packages
Name       : wget
Arch       : x86_64
Version    : 1.11.4
Release    : 3.el5_8.2
Size       : 1.4 M
Repo       : installed
Summary    : A utility for retrieving files using the HTTP or FTP protocols.
URL        : http://wget.sunsite.dk/
License    : GPL
Description: GNU Wget is a file retrieval utility which can use either the HTTP or
           : FTP protocols. Wget features include the ability to work in the
           : background while you are logged out, recursive retrieval of
           : directories, file name wildcard matching, remote file timestamp
           : storage and comparison, use of Rest with FTP servers and Range with
           : HTTP servers to retrieve files over slow or unstab
        RESULT
      end

      specify { expect(subject).to be__at_latest_version }
    end
  end

  describe '#_current_version' do
    before do
      expect(shell).to receive(:exec).with('rpm -qa thing') { result }
    end

    context 'not a package or not installed' do
      let(:result) { '' }
      specify { expect(subject.send(:_current_version)).to be_nil }
    end

    context 'installed' do
      let(:result) { 'thing-1.11.4-3.el5_8.2' }
      specify { expect(subject.send(:_current_version)).to eq '1.11.4-3.el5_8.2' }
    end
  end

  describe '#_remove' do
    before { expect(shell).to receive(:exec).with('yum remove -y thing') }

    context 'failed removal' do
      before { allow(shell).to receive(:last_exit_status) { 1 } }
      specify { expect(subject.send(:_remove)).to eq false }
    end

    context 'successful removal' do
      before { allow(shell).to receive(:last_exit_status) { 0 } }
      specify { expect(subject.send(:_remove)).to eq true }
    end
  end

  describe '#_upgrade' do
    before do
      expect(shell).to receive(:exec).with('yum upgrade -y thing') { output }
      expect(shell).to receive(:last_exit_status) { 0 }
    end

    context 'not yet installed' do
      let(:output) do
        <<-OUTPUT
Loaded plugins: fastestmirror
Determining fastest mirrors
 * base: mirror.lug.udel.edu
 * extras: ftpmirror.your.org
 * updates: ftp.usf.edu
base                                                                                                                                                                                                                                                     | 1.1 kB     00:00
extras                                                                                                                                                                                                                                                   | 2.1 kB     00:00
updates                                                                                                                                                                                                                                                  | 1.9 kB     00:00
updates/primary_db                                                                                                                                                                                                                                       | 374 kB     00:01
Setting up Upgrade Process
Package(s) thing available, but not installed.
No Packages marked for Update
        OUTPUT
      end

      specify { expect(subject.send(:_upgrade)).to eq false }
    end

    context 'already at latest version' do
      let(:output) do
        <<-OUTPUT
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.lug.udel.edu
 * extras: ftpmirror.your.org
 * updates: ftp.usf.edu
Setting up Update Process
No Packages marked for Update
        OUTPUT
      end

      specify { expect(subject.send(:_upgrade)).to eq false }
    end

    context 'installed but not at latest version' do
      let(:output) do
        <<-OUTPUT
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.lug.udel.edu
 * extras: ftpmirror.your.org
 * updates: ftp.usf.edu
Setting up Update Process
Resolving Dependencies
--> Running transaction check
--> Processing Dependency: curl = 7.15.5-15.el5 for package: curl-devel
--> Processing Dependency: curl = 7.15.5-15.el5 for package: curl-devel
---> Package curl.i386 0:7.15.5-16.el5_9 set to be updated
---> Package curl.x86_64 0:7.15.5-16.el5_9 set to be updated
--> Running transaction check
---> Package curl-devel.i386 0:7.15.5-16.el5_9 set to be updated
---> Package curl-devel.x86_64 0:7.15.5-16.el5_9 set to be updated
--> Finished Dependency Resolution

Dependencies Resolved

================================================================================================================================================================================================================================================================================
 Package                                                           Arch                                                          Version                                                                   Repository                                                      Size
================================================================================================================================================================================================================================================================================
Updating:
 curl                                                              i386                                                          7.15.5-16.el5_9                                                           updates                                                        235 k
 curl                                                              x86_64                                                        7.15.5-16.el5_9                                                           updates                                                        232 k
Updating for dependencies:
 curl-devel                                                        i386                                                          7.15.5-16.el5_9                                                           updates                                                        310 k
 curl-devel                                                        x86_64                                                        7.15.5-16.el5_9                                                           updates                                                        318 k

Transaction Summary
================================================================================================================================================================================================================================================================================
Install       0 Package(s)
Upgrade       4 Package(s)

Total download size: 1.1 M
Downloading Packages:
(1/4): curl-7.15.5-16.el5_9.x86_64.rpm                                                                                                                                                                                                                   | 232 kB     00:01
(2/4): curl-7.15.5-16.el5_9.i386.rpm                                                                                                                                                                                                                     | 235 kB     00:00
(3/4): curl-devel-7.15.5-16.el5_9.i386.rpm                                                                                                                                                                                                               | 310 kB     00:00
(4/4): curl-devel-7.15.5-16.el5_9.x86_64.rpm                                                                                                                                                                                                             | 318 kB     00:00
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                                                                           340 kB/s | 1.1 MB     00:03
Running rpm_check_debug
Running Transaction Test
Finished Transaction Test
Transaction Test Succeeded
Running Transaction
  Updating       : curl                                                                                                                                                                                                                                                     1/8
  Updating       : curl                                                                                                                                                                                                                                                     2/8
  Updating       : curl-devel                                                                                                                                                                                                                                               3/8
  Updating       : curl-devel                                                                                                                                                                                                                                               4/8
  Cleanup        : curl                                                                                                                                                                                                                                                     5/8
  Cleanup        : curl-devel                                                                                                                                                                                                                                               6/8
  Cleanup        : curl-devel                                                                                                                                                                                                                                               7/8
  Cleanup        : curl                                                                                                                                                                                                                                                     8/8

Updated:
  curl.i386 0:7.15.5-16.el5_9                                                                                                           curl.x86_64 0:7.15.5-16.el5_9

Dependency Updated:
  curl-devel.i386 0:7.15.5-16.el5_9                                                                                                     curl-devel.x86_64 0:7.15.5-16.el5_9

Complete!
        OUTPUT
      end

      specify { expect(subject.send(:_upgrade)).to eq true }
    end
  end
end
