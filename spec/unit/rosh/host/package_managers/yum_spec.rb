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
end
