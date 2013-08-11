require 'spec_helper'
require 'rosh/host/package_types/base'


describe Rosh::Host::PackageTypes::Base do
  let(:shell) do
    double 'Rosh::Host::Shell'
  end

  subject do
    Rosh::Host::PackageTypes::Base.new('test', shell, version: '1', status: 'ok')
  end

  its(:name) { should eq 'test' }
  its(:version) { should eq '1' }
  its(:status) { should eq 'ok' }

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
