require 'spec_helper'
require 'rosh/host/package'


describe Rosh::Host::Package do
  let(:shell) { double 'Rosh::Host::Shells::Fakie', :su? => false }

  before do
    Rosh::Host::Package.any_instance.stub(:load_strategy)
    allow(subject).to receive(:current_shell) { shell }
  end

  subject do
    Rosh::Host::Package.new(:type_meow, 'testie', 'example.com')
  end

  describe '#bin_path' do
    context 'default' do
      it 'calls #default_bin_path' do
        expect(subject).to receive(:default_bin_path)
        subject.bin_path
      end
    end
  end

  describe '#info' do
    it 'warns to define in the package type module' do
      expect(subject).to receive(:warn)
      subject.info
    end
  end

  describe '#installed?' do
    it 'warns to define in the package type module' do
      expect(subject).to receive(:warn)
      subject.installed?
    end
  end

  describe '#at_latest_version?' do
    it 'warns to define in the package type module' do
      expect(subject).to receive(:warn)
      subject.at_latest_version?
    end
  end

  describe '#current_version' do
    it 'warns to define in the package type module' do
      expect(subject).to receive(:warn)
      subject.current_version
    end
  end

  describe '#install' do
    context 'with version' do
      context 'skip_install? is true' do
        before { allow(subject).to receive(:skip_install?) { true } }
        specify { subject.install(version: '0.1.2').should be_nil }
      end

      context 'skip_install? is false' do
        before do
          allow(subject).to receive(:skip_install?) { false }
          allow(subject).to receive(:current_version).and_return('0.1.2', '1.2.3')
        end

        it 'tells the adapter to install using the version' do
          allow(subject).to receive(:notify_on_success)
          expect(subject).to receive(:install_package).with('1.2.3').and_return true
          subject.install(version: '1.2.3')
        end

        it 'delegates to notify observers' do
          allow(subject).to receive(:install_package) { true }
          expect(subject).to receive(:notify_on_success).with('1.2.3', '0.1.2', true)
          subject.install(version: '1.2.3')
        end
      end
    end
  end

  describe '#upgrade' do
    context 'successful' do
      before do
        allow(subject).to receive(:upgrade_package) { true }
      end

      it 'notifies observers with the old and new version' do
        allow(subject).to receive(:current_version).and_return '1', '2'
        expect(subject).to receive(:changed)
        expect(subject).to receive(:notify_observers).with(subject,
          attribute: :version, old: '1', new: '2', as_sudo: false
        )

        subject.upgrade
      end
    end

    context 'unsuccessful' do
      before do
        allow(subject).to receive(:upgrade_package) { false }
      end

      it 'notifies observers with the old and new version' do
        allow(subject).to receive(:current_version).and_return '1'
        expect(subject).to_not receive(:changed)
        expect(subject).to_not receive(:notify_observers)

        subject.upgrade
      end
    end
  end

  describe '#remove' do
    context 'not installed' do
      before { expect(subject).to receive(:installed?) { false } }

      context 'check state first is false' do
        before { expect(shell).to receive(:check_state_first?) { false } }

        it 'does not notify observers and returns false' do
          expect(subject).to receive(:current_version) { nil }
          expect(subject).to receive(:remove_package) { false }
          expect(subject).to_not receive(:changed)
          expect(subject).to_not receive(:notify_observers)

          expect(subject.remove).to be_false
        end
      end

      context 'check state first is true' do
        before { expect(shell).to receive(:check_state_first?) { true } }

        it 'does not notify observers and returns nil' do
          expect(subject).to_not receive(:current_version)
          expect(subject).to_not receive(:remove_package)
          expect(subject).to_not receive(:changed)
          expect(subject).to_not receive(:notify_observers)

          expect(subject.remove).to be_nil
        end
      end
    end

    context 'installed' do
      before { expect(subject).to receive(:installed?) { true } }

      context 'check state first is false' do
        before { expect(shell).to receive(:check_state_first?) { false } }

        context 'failed removal' do
          before { expect(subject).to receive(:remove_package) { false } }

          it 'does not notify observers and returns false' do
            expect(subject).to receive(:current_version) { '1' }
            expect(subject).to_not receive(:changed)
            expect(subject).to_not receive(:notify_observers)

            expect(subject.remove).to be_false
          end
        end

        context 'successful removal' do
          before { expect(subject).to receive(:remove_package) { true } }

          it 'notifies observers and returns true' do
            expect(subject).to receive(:current_version) { '1' }
            expect(subject).to receive(:changed)
            expect(subject).to receive(:notify_observers).with(subject,
              attribute: :version, old: '1', new: nil, as_sudo: false
            )

            expect(subject.remove).to be_true
          end
        end
      end

      context 'check state first is true' do
        before { expect(shell).to receive(:check_state_first?) { true } }

        context 'failed removal' do
          before { expect(subject).to receive(:remove_package) { false } }

          it 'does not notify observers and returns false' do
            expect(subject).to receive(:current_version) { '1' }
            expect(subject).to_not receive(:changed)
            expect(subject).to_not receive(:notify_observers)

            expect(subject.remove).to be_false
          end
        end

        context 'successful removal' do
          before { expect(subject).to receive(:remove_package) { true } }

          it 'notifies observers and returns true' do
            expect(subject).to receive(:current_version) { '1' }
            expect(subject).to receive(:changed)
            expect(subject).to receive(:notify_observers).with(subject,
              attribute: :version, old: '1', new: nil, as_sudo: false
            )

            expect(subject.remove).to be_true
          end
        end
      end
    end
  end

  describe '#load_strategy' do
    before do
      subject.stub(:load_strategy).and_call_original
    end

    context 'brew' do
      it 'extends self with Brew methods' do
        require 'rosh/host/package_types/brew'
        expect(subject).to receive(:extend).with Rosh::Host::PackageTypes::Brew
        subject.send(:load_strategy, :brew)
      end
    end
  end

  describe '#skip_install?' do
    context 'check_state_first? is true' do
      before { shell.stub(:check_state_first?).and_return true }

      context 'package is installed' do
        before { subject.stub(:installed?).and_return true }

        context 'with version provided' do
          before { subject.stub(:current_version).and_return '0.1.2' }

          context 'equal to current_version' do
            specify { subject.send(:skip_install?, '0.1.2').should be_true }
          end

          context 'greater than current_version' do
            specify { subject.send(:skip_install?, '0.1.3').should be_false }
          end
        end

        context 'with no version provided' do
          specify { subject.send(:skip_install?).should be_true }
        end
      end

      context 'package not installed' do
        before { subject.stub(:installed?).and_return false }
        specify { subject.send(:skip_install?).should be_false }
      end
    end

    context 'check_state_first? is false' do
      before { shell.stub(:check_state_first?).and_return false }
      specify { subject.send(:skip_install?).should be_false }
    end
  end
end
