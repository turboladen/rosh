require 'spec_helper'
require 'rosh/host/package'


describe Rosh::Host::Package do
  let(:shell) { double 'Rosh::Host::Shells::Fakie' }

  before do
    Rosh::Host::Package.any_instance.stub(:load_adapter)
    allow(subject).to receive(:current_shell) { shell }
  end

  subject do
    Rosh::Host::Package.new('type_meow', 'testie', 'example.com')
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
          allow(subject).to receive(:_current_version).and_return('0.1.2', '1.2.3')
        end

        it 'tells the adapter to install using the version' do
          allow(subject).to receive(:notify_on_success)
          expect(subject).to receive(:_install).with('1.2.3').and_return true
          subject.install(version: '1.2.3')
        end

        it 'delegates to notify observers' do
          allow(subject).to receive(:_install) { true }
          expect(subject).to receive(:notify_on_success).with('1.2.3', '0.1.2', true)
          subject.install(version: '1.2.3')
        end
      end
    end
  end

  describe '#load_adapter' do
    before do
      subject.unstub(:load_adapter)
    end

    context 'brew' do
      it 'extends self with Brew methods' do
        subject.class.should_receive(:include).with Rosh::Host::PackageTypes::Brew
        subject.send(:load_adapter, :brew)
      end
    end
  end

  describe '#skip_install?' do
    context 'check_state_first? is true' do
      before { shell.stub(:check_state_first?).and_return true }

      context 'package is installed' do
        before { subject.stub(:_installed?).and_return true }

        context 'with version provided' do
          before { subject.stub(:_current_version).and_return '0.1.2' }

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
        before { subject.stub(:_installed?).and_return false }
        specify { subject.send(:skip_install?).should be_false }
      end
    end

    context 'check_state_first? is false' do
      before { shell.stub(:check_state_first?).and_return false }
      specify { subject.send(:skip_install?).should be_false }
    end
  end
end
