require 'spec_helper'
require 'rosh/host/package_managers/apt'


describe Rosh::Host::PackageManagers::Apt do
  let(:shell) do
    s = double 'Rosh::Host::Shell'
    s.stub_chain(:history, :last, :[], :zero?)

    s
  end

  let(:observer) do
    o = double 'Observer'
    o.define_singleton_method(:update) do |one, two|
      #
    end

    o
  end

  subject do
    Object.send(:include, Rosh::Host::PackageManagers::Apt)
  end

  before do
    subject.instance_variable_set(:@shell, shell)
  end

  describe '#cache' do
    let(:cache_dump) do
      <<-DUMP
Package: psemu-sound-oss
Package: psemu-sound-oss:i386
Package: mp3wrap
 Version: 0.5-3
Package: mp3wrap:i386
 Version: 0.5-3
Package: libxml-simpleobject-perl
 Version: 0.53-2
      DUMP
    end

    before do
      shell.should_receive(:exec).with("apt-cache dump | grep 'Package:\\||*Version:'").
        and_return cache_dump
    end

    it 'returns an Hash of cached packages' do
      cache = subject.cache
      cache.should == {
        'psemu-sound-oss' => { arch: 'i386', version: nil },
        'mp3wrap' => { arch: 'i386', version: '0.5-3' },
        'libxml-simpleobject-perl' => { arch: '', version: '0.53-2' }
      }
    end
  end

  describe '#update_cache' do
    before do
      shell.should_receive(:exec).with('apt-get update').and_return output
    end

    context 'cache does not change during update' do
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

      context 'successful command' do
        before { shell.stub(:last_exit_status).and_return 0 }

        it 'returns true and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.update_cache.should == true
        end
      end

      context 'unsuccessful command' do
        before { shell.stub(:last_exit_status).and_return 1 }

        it 'returns false and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.update_cache.should == false
        end
      end
    end

    context 'cache changes after update' do
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

      context 'successful command' do
        before { shell.stub(:last_exit_status).and_return 0 }

        it 'returns true and notifies observers' do
          subject.should_receive(:changed)
          subject.should_receive(:notify_observers).
            with(subject, attribute: :cache, old: false, new: true)

          subject.update_cache.should == true
        end
      end

      context 'unsuccessful command' do
        before { shell.stub(:last_exit_status).and_return 1 }

        it 'returns false and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.update_cache.should == false
        end
      end
    end
  end

  describe '#update_cache!' do
    before { shell.should_receive(:exec).with('apt-get update') }

    context 'cache does not change after update' do
      before do
        subject.should_receive(:cache).and_return []
        subject.should_receive(:cache).and_return []
      end

      context 'successful command' do
        before { shell.stub(:last_exit_status).and_return 0 }

        it 'returns true and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.update_cache!.should == true
        end
      end

      context 'unsuccessful command' do
        before { shell.stub(:last_exit_status).and_return 1 }

        it 'returns false and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.update_cache!.should == false
        end
      end
    end

    context 'cache changes after update' do
      before do
        subject.should_receive(:cache).and_return []
        subject.should_receive(:cache).and_return %w[new_package]
      end

      context 'successful command' do
        before { shell.stub(:last_exit_status).and_return 0 }

        it 'returns true and notifies observers' do
          subject.should_receive(:changed)
          subject.should_receive(:notify_observers).
            with(subject, attribute: :cache, old: [], new: %w[new_package])

          subject.update_cache!.should == true
        end
      end

      context 'unsuccessful command' do
        before { shell.stub(:last_exit_status).and_return 1 }

        it 'returns false and does not notify observers' do
          subject.should_not_receive(:changed)
          subject.should_not_receive(:notify_observers)

          subject.update_cache!.should == false
        end
      end
    end
  end

  describe '#upgrade_packages' do
    let(:output) { 'some output' }

    before do
      subject.stub(:packages).and_return []
      shell.should_receive(:exec).with('apt-get upgrade -y').and_return output
    end

    context 'no packages to upgrade' do
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

        let(:deb_package) { double 'Rosh::Host::PackageTypes::Deb' }

        it 'returns true and notifies observers' do
          subject.should_receive(:create).and_return deb_package
          subject.should_receive(:changed)
          subject.should_receive(:notify_observers).
            with(subject, attribute: :packages, old: [], new: [deb_package])

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
    let(:output) do
       <<-EOF
The following packages will be upgraded:
  accountsservice apparmor
  base-files bash
4 upgraded, 0 newly installed, 0 to remove and 3 not upgraded.
      EOF
    end

    it 'returns an array of new Deb packages' do
      result = subject.send(:extract_upgradable_packages, output)
      result.should  eq %w[accountsservice apparmor base-files bash]
    end
  end
end
