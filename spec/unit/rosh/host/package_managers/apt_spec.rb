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
      shell.should_receive(:exec).with("apt-cache dump | grep 'Package:\||*Version:'").
        and_return cache_dump
    end

    it 'returns an Array of cached packages' do
      subject.should_receive(:create).
        with('psemu-sound-oss', architecture: 'i386')
      subject.should_receive(:create).
        with('mp3wrap', architecture: 'i386', version: '0.5-3')
      subject.should_receive(:create).
        with('libxml-simpleobject-perl', architecture: '', version: '0.53-2')

      cache = subject.cache
      cache.should be_an Array
      cache.size.should == 3
    end
  end

  describe '#update_cache' do
    it 'runs "apt-get update"' do
      shell.should_receive(:exec).with('apt-get update').and_return ''
      subject.update_cache
    end

    context 'stdout includes Get:' do
      before do
        subject.add_observer(observer)
        shell.should_receive(:exec).with('apt-get update').and_return <<-EOF
things1
Get: stuff1
things2
Get: stuff2
        EOF
      end

      it 'updates observers' do
        observer.should_receive(:update).
          with(subject, attribute: :update_cache, old: nil, new: ['Get: stuff1', 'Get: stuff2'])
        subject.update_cache
      end
    end
  end

  describe '#upgrade_packages' do
    it 'runs "apt-get upgrade -y"' do
      shell.should_receive(:exec).with('apt-get upgrade -y').and_return ''
      subject.upgrade_packages
    end

    context 'stdout includes Get:' do
      before do
        subject.add_observer(observer)
        shell.should_receive(:exec).with('apt-get upgrade -y').and_return <<-EOF
The following packages will be upgraded:
  accountsservice apparmor
  base-files bash
13 upgraded, 0 newly installed, 0 to remove and 3 not upgraded.
        EOF
      end

      let(:expected_packages) do
        %w[accountsservice apparmor base-files bash]
      end

      it 'updates observers' do
        observer.should_receive(:update)
        expected_packages.each do |pkg|
          Rosh::Host::PackageTypes::Apt.should_receive(:new).with(shell, pkg)
        end

        subject.upgrade_packages
      end
    end
  end
end
