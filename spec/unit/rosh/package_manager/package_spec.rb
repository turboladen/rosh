require 'rosh/package_manager/package'

RSpec.describe Rosh::PackageManager::Package do
  before do
    described_class.any_instance.stub(:adapter)
    allow(package).to receive(:adapter) { adapter }
  end

  subject(:package) do
    described_class.new('test_pkg', 'example.com')
  end

  describe '#install' do
    context 'without version' do
      context 'latest is already installed' do
        before do
          allow(package).to receive(:installed?) { true }
          allow(package).to receive(:at_latest_version?) { true }
          allow(package).to receive(:version) { '0.0.1' }
        end

        it 'does not cause change' do
          expect(package).to receive(:change_if).with(false)

          package.install
        end
      end
    end
  end

  describe '#upgrade' do
    context 'successful' do
      before do
        allow(package).to receive(:upgrade_package) { true }
      end

      it 'notifies observers with the old and new version' do
        allow(package).to receive(:current_version).and_return '1', '2'
        expect(package).to receive(:changed)
        expect(package).to receive(:notify_observers).with(package,
          attribute: :version, old: '1', new: '2', as_sudo: false
                                                          )

        package.upgrade
      end
    end

    context 'unsuccessful' do
      before do
        allow(package).to receive(:upgrade_package) { false }
      end

      it 'notifies observers with the old and new version' do
        allow(package).to receive(:current_version).and_return '1'
        expect(package).to_not receive(:changed)
        expect(package).to_not receive(:notify_observers)

        package.upgrade
      end
    end
  end

  describe '#remove' do
    context 'not installed' do
      before { expect(package).to receive(:installed?) { false } }

      context 'check state first is false' do
        before { expect(shell).to receive(:check_state_first?) { false } }

        it 'does not notify observers and returns false' do
          expect(package).to receive(:current_version) { nil }
          expect(package).to receive(:remove_package) { false }
          expect(package).to_not receive(:changed)
          expect(package).to_not receive(:notify_observers)

          expect(package.remove).to be_false
        end
      end

      context 'check state first is true' do
        before { expect(shell).to receive(:check_state_first?) { true } }

        it 'does not notify observers and returns nil' do
          expect(package).to_not receive(:current_version)
          expect(package).to_not receive(:remove_package)
          expect(package).to_not receive(:changed)
          expect(package).to_not receive(:notify_observers)

          expect(package.remove).to be_nil
        end
      end
    end

    context 'installed' do
      before { expect(package).to receive(:installed?) { true } }

      context 'check state first is false' do
        before { expect(shell).to receive(:check_state_first?) { false } }

        context 'failed removal' do
          before { expect(package).to receive(:remove_package) { false } }

          it 'does not notify observers and returns false' do
            expect(package).to receive(:current_version) { '1' }
            expect(package).to_not receive(:changed)
            expect(package).to_not receive(:notify_observers)

            expect(package.remove).to be_false
          end
        end

        context 'successful removal' do
          before { expect(package).to receive(:remove_package) { true } }

          it 'notifies observers and returns true' do
            expect(package).to receive(:current_version) { '1' }
            expect(package).to receive(:changed)
            expect(package).to receive(:notify_observers).with(package,
              attribute: :version, old: '1', new: nil, as_sudo: false
                                                              )

            expect(package.remove).to be_true
          end
        end
      end

      context 'check state first is true' do
        before { expect(shell).to receive(:check_state_first?) { true } }

        context 'failed removal' do
          before { expect(package).to receive(:remove_package) { false } }

          it 'does not notify observers and returns false' do
            expect(package).to receive(:current_version) { '1' }
            expect(package).to_not receive(:changed)
            expect(package).to_not receive(:notify_observers)

            expect(package.remove).to be_false
          end
        end

        context 'successful removal' do
          before { expect(package).to receive(:remove_package) { true } }

          it 'notifies observers and returns true' do
            expect(package).to receive(:current_version) { '1' }
            expect(package).to receive(:changed)
            expect(package).to receive(:notify_observers).with(package,
              attribute: :version, old: '1', new: nil, as_sudo: false
                                                              )

            expect(package.remove).to be_true
          end
        end
      end
    end
  end

  describe '#load_strategy' do
    before do
      package.stub(:load_strategy).and_call_original
    end

    context 'brew' do
      it 'extends self with Brew methods' do
        require 'rosh/host/package_types/brew'
        expect(package).to receive(:extend).with Rosh::Host::PackageTypes::Brew
        package.send(:load_strategy, :brew)
      end
    end
  end

  describe '#skip_install?' do
    context 'check_state_first? is true' do
      before { shell.stub(:check_state_first?).and_return true }

      context 'package is installed' do
        before { package.stub(:installed?).and_return true }

        context 'with version provided' do
          before { package.stub(:current_version).and_return '0.1.2' }

          context 'equal to current_version' do
            specify { package.send(:skip_install?, '0.1.2').should be_true }
          end

          context 'greater than current_version' do
            specify { package.send(:skip_install?, '0.1.3').should be_false }
          end
        end

        context 'with no version provided' do
          specify { package.send(:skip_install?).should be_true }
        end
      end

      context 'package not installed' do
        before { package.stub(:installed?).and_return false }
        specify { package.send(:skip_install?).should be_false }
      end
    end

    context 'check_state_first? is false' do
      before { shell.stub(:check_state_first?).and_return false }
      specify { package.send(:skip_install?).should be_false }
    end
  end
end
