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
    o.define_singleton_method(:update) do |one, two, three, four|
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
          with(subject, :update_cache, nil, ['Get: stuff1', 'Get: stuff2'])
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
