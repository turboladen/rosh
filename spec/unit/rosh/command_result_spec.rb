require 'spec_helper'
require 'rosh/shell/private_command_result'


describe Rosh::Shell::PrivateCommandResult do
  let(:ruby_object) { double 'Object' }

  subject do
    described_class.new(ruby_object, 0)
  end

  specify { expect(subject.ruby_object).to eq ruby_object }
  specify { expect(subject.exit_status).to be_zero }

  describe '#initialize' do
    context 'ruby_object is nil and stdout is not empty' do
      subject do
        described_class.new(nil, 1, 'stuff')
      end

      it 'sets ruby_object to stdout' do
        subject.ruby_object.should eq 'stuff'
      end
    end
  end

  describe '#exception?' do
    let(:error) { Exception.new }

    context 'an exception was passed in' do
      subject { described_class.new(error, 1) }
      specify { subject.exception?.should be_true }
    end

    context 'an exception was not passed in' do
      subject { described_class.new('stuff', 0) }
      specify { subject.exception?.should be_false }
    end
  end

  describe '#failed?' do
    context 'exit status is zero' do
      before do
        subject.instance_variable_set(:@exit_status, 0)
      end

      it { should_not be_failed }
    end

    context 'exit status is not zero' do
      before do
        subject.instance_variable_set(:@exit_status, 10)
      end

      it { should be_failed }
    end
  end
end
