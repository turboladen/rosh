require 'spec_helper'
require 'rosh/command_result'


describe Rosh::CommandResult do
  let(:ruby_object) { double 'Object' }

  subject do
    Rosh::CommandResult.new(ruby_object, 0)
  end

  its(:ruby_object) { should eq ruby_object }
  its(:exit_status) { should be_zero }

  describe '#initialize' do
    context 'ruby_object is nil and stdout is not empty' do
      subject do
        Rosh::CommandResult.new(nil, 1, 'stuff')
      end

      it 'sets ruby_object to stdout' do
        subject.ruby_object.should eq 'stuff'
      end
    end
  end

  describe '#exception?' do
    let(:error) { Exception.new }

    context 'an exception was passed in' do
      subject { Rosh::CommandResult.new(error, 1) }
      specify { subject.exception?.should be_true }
    end

    context 'an exception was not passed in' do
      subject { Rosh::CommandResult.new('stuff', 0) }
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
