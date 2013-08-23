require 'spec_helper'
require 'rosh/host/package_manager'


describe Rosh::Host::PackageManager do
  let(:shell) { double 'Rosh::Host::Shell::Fakie' }

  before do
    allow(subject).to receive(:current_shell) { shell }
  end

  subject do
    allow_any_instance_of(Rosh::Host::PackageManager).to receive(:load_adapter)
    pm = Rosh::Host::PackageManager.new('testie', 'example.com')

    pm
  end

  describe '#[]' do
    it 'calls #create with the package name' do
      subject.should_receive(:create_package).with('test')
      subject['test']
    end
  end

  describe '#installed_packages' do
    it 'calls #_installed_packages on the adapter' do
      expect(subject).to receive(:_installed_packages)

      subject.installed_packages
    end
  end

  describe '#update_definitions' do
    context 'no definitions updated' do
      before do
        expect(subject).to receive(:_update_definitions) { '' }
        expect(subject).to receive(:_extract_updated_definitions) { [] }
      end

      context 'failed command' do
        before { allow(shell).to receive(:last_exit_status) { 1 } }

        it 'does not notify observers' do
          expect(subject).to_not receive(:changed)
          expect(subject).to_not receive(:notify_observers)

          subject.update_definitions
        end
      end

      context 'successful command' do
        before { expect(shell).to receive(:last_exit_status) { 0 } }

        it 'does not notify observers' do
          expect(subject).to_not receive(:changed)
          expect(subject).to_not receive(:notify_observers)

          subject.update_definitions
        end
      end
    end

    context 'definitions updated' do
      let(:updated_definition) { double 'updated definition' }
      let(:command_output) { double 'command output' }

      before do
        expect(subject).to receive(:_update_definitions) { command_output }
        expect(subject).to receive(:_extract_updated_definitions) { [updated_definition] }
      end

      context 'failed command' do
        before { allow(shell).to receive(:last_exit_status) { 1 } }

        it 'does not notify observers' do
          expect(subject).to_not receive(:changed)
          expect(subject).to_not receive(:notify_observers)

          subject.update_definitions
        end
      end

      context 'successful command' do
        before do
          allow(shell).to receive(:last_exit_status) { 0 }
          expect(shell).to receive(:su?) { false }
        end

        it 'notifies observers' do
          expect(subject).to receive(:changed)
          expect(subject).to receive(:notify_observers).
            with(subject,
            attribute: :package_definitions,
            old: [],
            new: [updated_definition],
            as_sudo: false
          )

          subject.update_definitions
        end
      end
    end
  end

  describe '#upgrade_packages' do
    context 'no packages upgraded' do
      before do
        expect(subject).to receive(:_installed_packages) { [] }
        expect(subject).to receive(:_upgrade_packages) { [] }
        expect(subject).to receive(:_extract_upgraded_packages) { [] }
      end

      context 'failed command' do
        before { expect(shell).to receive(:last_exit_status) { 1 } }

        it 'does not notify observers' do
          expect(subject).to_not receive(:changed)
          expect(subject).to_not receive(:notify_observers)

          subject.upgrade_packages
        end
      end

      context 'successful command' do
        before { expect(shell).to receive(:last_exit_status) { 0 } }

        it 'does not notify observers' do
          expect(subject).to_not receive(:changed)
          expect(subject).to_not receive(:notify_observers)

          subject.upgrade_packages
        end
      end
    end

    context 'packages upgraded' do
      let(:upgraded_package) { double 'upgraded package' }
      let(:command_output) { double 'command output' }

      before do
        expect(subject).to receive(:_installed_packages) { [] }
        expect(subject).to receive(:_upgrade_packages) { command_output }
        expect(subject).to receive(:_extract_upgraded_packages) { [upgraded_package] }
      end

      context 'failed command' do
        before { expect(shell).to receive(:last_exit_status) { 1 } }

        it 'does not notify observers' do
          expect(subject).to_not receive(:changed)
          expect(subject).to_not receive(:notify_observers)

          subject.upgrade_packages
        end
      end

      context 'successful command' do
        before do
          expect(shell).to receive(:last_exit_status) { 0 }
          expect(shell).to receive(:su?) { false }
        end

        it 'notifies observers' do
          expect(subject).to receive(:changed)
          expect(subject).to receive(:notify_observers).
            with(subject,
            attribute: :_installed_packages,
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
