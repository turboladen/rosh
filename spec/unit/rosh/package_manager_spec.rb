require 'rosh/package_manager'

RSpec.describe Rosh::PackageManager do
  let(:shell) { double 'Rosh::Shell' }
  let(:adapter) { double 'Rosh::PackageManager::ManagerAdapters::Test' }

  subject(:package_manager) do
    Rosh::PackageManager.new('example.com')
  end

  before do
    allow(package_manager).to receive(:current_shell) { shell }
    allow(package_manager).to receive(:adapter) { adapter }
    allow(package_manager).to receive(:echo_rosh_command)
  end

  describe '#[]' do
    let(:package) { double 'Rosh::PackageManager::Package' }

    it 'builds a new Package object' do
      allow(package).to receive(:add_observer)
      expect(package_manager).to receive(:package).with('test') { package }

      package_manager['test']
    end

    it 'adds itself as an observer of the Package' do
      allow(package_manager).to receive(:package).with('test') { package }
      expect(package).to receive(:add_observer).with(package_manager)

      package_manager['test']
    end
  end

  describe '#installed_packages' do
    it 'delegates to the adapter' do
      expect(adapter).to receive(:installed_packages)

      package_manager.installed_packages
    end
  end

  describe '#update_definitions' do
    context 'no definitions updated' do
      pending 'Implementation of determining which packages were updated.'
    end

    context 'definitions updated' do
      let(:updated_definition) { double 'updated definition' }
      let(:command_output) { double 'command output' }

      before do
        expect(adapter).to receive(:update_definitions) { [updated_definition] }
      end

      context 'failed command' do
        before { allow(shell).to receive(:last_exit_status) { 1 } }

        it 'does not notify observers' do
          expect(package_manager).to receive(:change_if).with(true).and_yield
          expect(package_manager).to receive(:notify_about).with(package_manager,
            :package_definitions,
            from: '?',
            to: [updated_definition],
            criteria: false
                                                                )

          package_manager.update_definitions
        end
      end

      context 'successful command' do
        before do
          allow(shell).to receive(:last_exit_status) { 0 }
        end

        it 'notifies observers' do
          expect(package_manager).to receive(:change_if).with(true).and_yield
          expect(package_manager).to receive(:notify_about).with(package_manager,
            :package_definitions,
            from: '?',
            to: [updated_definition],
            criteria: true
                                                                )

          package_manager.update_definitions
        end
      end
    end
  end

  describe '#upgrade_packages' do
    context 'no packages upgraded' do
      before do
        expect(package_manager).to receive(:installed_packages) { [] }
        expect(adapter).to receive(:upgrade_packages) { [] }
      end

      context 'failed command' do
        before { expect(shell).to receive(:last_exit_status) { 1 } }

        it 'does not notify observers' do
          expect(package_manager).to receive(:change_if).with(true).and_yield
          expect(package_manager).to_not receive(:notify_about)

          package_manager.upgrade_packages
        end
      end

      context 'successful command' do
        before { expect(shell).to receive(:last_exit_status) { 0 } }

        it 'does not notify observers' do
          expect(package_manager).to receive(:change_if).with(true).and_yield
          expect(package_manager).to_not receive(:notify_about)

          package_manager.upgrade_packages
        end
      end
    end

    context 'packages upgraded' do
      let(:old_package) do
        double 'Rosh::PackageManager::Package', name: 'test_pkg', version: 1
      end

      let(:new_package) do
        double 'Rosh::PackageManager::Package', name: 'test_pkg', version: 2
      end

      before do
        allow(package_manager).to receive(:installed_packages) { [old_package] }
        expect(package_manager).to receive(:change_if).with(true).and_yield

        expect(adapter).to receive(:upgrade_packages) { [new_package] }
      end

      context 'failed command' do
        before { expect(shell).to receive(:last_exit_status) { 1 } }

        it 'calls #notify_about with negative criteria for each upgraded package' do
          expect(package_manager).to receive(:notify_about).with(new_package,
            :package_version,
            from: 1,
            to: 2,
            criteria: false
                                                                )

          package_manager.upgrade_packages
        end
      end

      context 'successful command' do
        before { expect(shell).to receive(:last_exit_status) { 0 } }

        it 'calls #notify_about with positive criteria for each upgraded package' do
          expect(package_manager).to receive(:notify_about).with(new_package,
            :package_version,
            from: 1,
            to: 2,
            criteria: true
                                                                )

          package_manager.upgrade_packages
        end
      end
    end
  end
end
