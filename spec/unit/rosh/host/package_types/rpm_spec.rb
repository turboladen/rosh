require 'spec_helper'
require 'rosh/host/package_types/rpm'


describe Rosh::Host::PackageTypes::Rpm do
  let(:shell) { double 'Rosh::Host::Shell' }

  subject do
    Rosh::Host::PackageTypes::Rpm.new('thing', shell)
  end

  describe '#info' do
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
      shell.should_receive(:exec).with('yum info thing').and_return output
    end

    it 'parses each field and value to a Hash' do
      subject.info.should == {
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

  describe 'installed?' do
    context 'is not installed' do
      before do
        shell.should_receive(:exec).with('yum info thing')
        shell.stub(:last_exit_status).and_return 1
      end

      specify { subject.should_not be_installed }
    end

    context 'is installed' do
      before do
        shell.should_receive(:exec).with('yum info thing')
        shell.stub(:last_exit_status).and_return 0
      end

      specify { subject.should be_installed }
    end
  end

  describe '#install' do
    context 'with version' do
      it 'passes the version to the command' do
        subject.should_receive(:installed?).and_return true
        shell.should_receive(:exec).with('yum install -y thing-1.2.3')
        shell.should_receive(:last_exit_status).and_return 0

        subject.install(version: '1.2.3')
      end
    end

    context 'no version' do
      before do
        shell.should_receive(:exec).with('yum install -y thing')
      end

      context 'package was already installed' do
        before do
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

      context 'package not yet installed' do
        before do
          subject.should_receive(:installed?).and_return false
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
              with(subject, attribute: :version, old: nil, new: '1.2.3')

            subject.install
          end
        end
      end
    end
  end

  describe '#remove' do
    before do
      shell.should_receive(:exec).with('yum remove -y thing')
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
            with(subject, attribute: :version, old: '1.2.3', new: nil)

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

      before do
        subject.should_receive(:installed?).and_return false
        shell.should_receive(:exec).with('yum upgrade -y thing').and_return output
        shell.should_receive(:last_exit_status).and_return 0
      end

      it 'returns false and does not notify observers' do
        subject.should_not_receive(:update)
        subject.should_not_receive(:notify_observers)

        subject.upgrade.should == false
      end
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

      before do
        subject.should_receive(:installed?).and_return true
        subject.stub_chain(:info, :[])
        shell.should_receive(:exec).with('yum upgrade -y thing').and_return output
        shell.should_receive(:last_exit_status).and_return 0
      end

      it 'returns false and does not notify observers' do
        subject.should_not_receive(:update)
        subject.should_not_receive(:notify_observers)

        subject.upgrade.should == false
      end
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

      before do
        subject.should_receive(:installed?).and_return true
        subject.stub_chain(:info, :[]).and_return '0.1.2', '1.2.3'
        shell.should_receive(:exec).with('yum upgrade -y thing').and_return output
        shell.should_receive(:last_exit_status).and_return 0
      end

      it 'returns true and notifies observers' do
        subject.should_receive(:changed)
        subject.should_receive(:notify_observers).
          with(subject, attribute: :version, old: '0.1.2', new: '1.2.3')

        subject.upgrade.should == true
      end
    end
  end
end
