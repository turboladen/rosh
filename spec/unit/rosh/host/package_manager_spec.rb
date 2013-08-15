require 'spec_helper'
require 'rosh/host/package_manager'


describe Rosh::Host::PackageManager do
  let(:shell) { double 'Rosh::Host::Shell::Fakie' }

  let(:adapter) do
    double 'Rosh::Host::PackageManager::Fakie'
  end

  subject do
    pm = Rosh::Host::PackageManager.new('testie', 'meow', shell)
    pm.stub(:adapter).and_return adapter

    pm
  end

  describe '#[]' do
    it 'calls #create with the package name' do
      adapter.should_receive(:create_package).with('test')
      subject['test']
    end
  end

  describe '#upgrade_packages' do
    context 'no packages upgraded' do
      before do
        allow(adapter).to receive(:installed_packages) { [] }
        allow(adapter).to receive(:upgrade_packages) { [] }
        allow(adapter).to receive(:extract_upgraded_packages) { [] }
      end

      context 'failed command' do
        before { allow(shell).to receive(:last_exit_status) { 1 } }

        it 'does not notify observers' do
          expect(adapter).to_not receive(:changed)
          expect(adapter).to_not receive(:notify_observers)

          subject.upgrade_packages
        end
      end

      context 'successful command' do
        before { allow(shell).to receive(:last_exit_status) { 0 } }

        it 'does not notify observers' do
          expect(adapter).to_not receive(:changed)
          expect(adapter).to_not receive(:notify_observers)

          subject.upgrade_packages
        end
      end
    end

    context 'packages upgraded' do
      let(:upgraded_package) { double 'upgraded package' }
      let(:command_output) { double 'command output' }

      before do
        allow(adapter).to receive(:installed_packages) { [] }
        allow(adapter).to receive(:upgrade_packages) { command_output }
        allow(adapter).to receive(:extract_upgraded_packages) { [upgraded_package] }
      end

      context 'failed command' do
        before { allow(shell).to receive(:last_exit_status) { 1 } }

        it 'does not notify observers' do
          expect(adapter).to_not receive(:changed)
          expect(adapter).to_not receive(:notify_observers)

          subject.upgrade_packages
        end
      end

      context 'successful command' do
        before do
          allow(shell).to receive(:last_exit_status) { 0 }
          expect(shell).to receive(:su?) { false }
        end

        it 'notifies observers' do
          expect(adapter).to receive(:changed)
          expect(adapter).to receive(:notify_observers).
            with(adapter,
            attribute: :installed_packages,
            old: [],
            new: [upgraded_package],
            as_sudo: false
          )

          subject.upgrade_packages
        end
      end
    end
  end
end
