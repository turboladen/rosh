require 'spec_helper'
require 'rosh/host/package'


describe Rosh::Host::Package do
  let(:adapter) do
    double 'Rosh::Host::PackageTypes::Fakie'
  end

  let(:shell) do
    double 'Rosh::Host::Shells::Fakie'
  end

  subject do
    package = Rosh::Host::Package.new('type_meow', 'testie', shell)
    package.stub(:adapter).and_return adapter

    package
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
          allow(adapter).to receive(:current_version).and_return('0.1.2', '1.2.3')
        end

        it 'tells the adapter to install using the version' do
          allow(subject).to receive(:notify_on_success)
          expect(adapter).to receive(:install).with('1.2.3').and_return true
          subject.install(version: '1.2.3')
        end

        it 'delegates to notify observers' do
          allow(adapter).to receive(:install) { true }
          expect(subject).to receive(:notify_on_success).with('1.2.3', '0.1.2', true)
          subject.install(version: '1.2.3')
        end
      end
    end
  end

  describe '#create_adapter' do
    subject do
      Rosh::Host::Package.new('type_meow', 'testie', shell)
    end

    context 'brew' do
      it 'creates a Brew package object' do
        pkg = subject.send(:create_adapter, :brew, 'testie', shell)

        pkg.should be_a Rosh::Host::PackageTypes::Brew
      end
    end
  end

  describe '#skip_install?' do
    context 'check_state_first? is true' do
      before { shell.stub(:check_state_first?).and_return true }

      context 'package is installed' do
        before { adapter.stub(:installed?).and_return true }

        context 'with version provided' do
          before { adapter.stub(:current_version).and_return '0.1.2' }

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
        before { adapter.stub(:installed?).and_return false }
        specify { subject.send(:skip_install?).should be_false }
      end
    end

    context 'check_state_first? is false' do
      before { shell.stub(:check_state_first?).and_return false }
      specify { subject.send(:skip_install?).should be_false }
    end
  end
end
