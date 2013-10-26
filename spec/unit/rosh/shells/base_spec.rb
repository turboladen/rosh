require 'spec_helper'
require 'rosh/host/shells/base'


describe Rosh::Host::Shells::Base do
  subject do
    Rosh::Host::Shells::Base.new
  end

  its(:history) { should eq [] }
  its(:sudo) { should be_false }

  describe '#check_state_first?' do
    it 'defaults to false' do
      subject.check_state_first?.should be_false
    end
  end

  describe '#check_state_first=' do
    it 'toggles the setting' do
      expect {
        subject.check_state_first = true
      }.to change { subject.check_state_first? }.
        from(false).to(true)
    end
  end

  describe '#last_result' do
    before do
      subject.instance_variable_set(:@history, [1, { output: 'hi' } ])
    end

    context 'as #last_result' do
      it 'returns the last :output item from the history' do
        subject.last_result.should == 'hi'
      end
    end

    context 'as #__' do
      it 'returns the last :output item from the history' do
        subject.__.should == 'hi'
      end
    end

    context 'no history' do
      before { subject.instance_variable_set(:@history, []) }
      specify { expect(subject.last_result).to be_nil }
    end
  end

  describe '#last_exit_status' do
    before do
      subject.instance_variable_set(:@history, [1, { exit_status: 123 } ])
    end

    context 'as #last_exit_status' do
      it 'returns the last :exit_status item from the history' do
        subject.last_exit_status.should == 123
      end
    end

    context 'as #_?' do
      it 'returns the last :exit_status item from the history' do
        subject._?.should == 123
      end
    end

    context 'no history' do
      before { subject.instance_variable_set(:@history, []) }
      specify { expect(subject.last_exit_status).to be_nil }
    end
  end

  describe '#last_exception' do
    let(:exception) { Exception.new('hi') }

    before do
      subject.instance_variable_set(:@history, [1, { output: exception } ])
    end

    context 'as #last_exception' do
      it 'returns the last :output item from the history that is an Exception' do
        subject.last_exception.should == exception
      end
    end

    context 'as #_!' do
      it 'returns the last :output item from the history that is an Exception' do
        subject._!.should == exception
      end
    end

    context 'no history' do
      before { subject.instance_variable_set(:@history, []) }
      specify { expect(subject.last_exception).to be_nil }
    end
  end

  describe '#su' do
    it 'sets sudo to true, calls the block, then sets back to false' do
      subject.su do
        subject.instance_variable_get(:@sudo).should be_true
      end

      subject.instance_variable_get(:@sudo).should be_false
    end

    it 'returns the return value from the block' do
      subject.su { 'hi' }.should == 'hi'
    end
  end

  describe '#process' do
    let(:result) { 'the result' }
    let(:exit_status) { 123 }
    let(:ssh_output) { 'the output' }
    let(:today) { Date.today.to_s }
    let(:args) { { arg1: 1, arg2: 2 } }

    let(:blk) do
      proc { [result, exit_status, ssh_output] }
    end

    it 'adds info about the executed command to @history' do
      Time.stub(:now).and_return today

      expect {
        subject.send(:process, 'the command', **args, &blk)
      }.to change { subject.history.size }.from(0).to(1)

      subject.history.last.should == {
        time: today,
        command: 'the command',
        arguments: args,
        output: result,
        exit_status: exit_status,
        ssh_output: ssh_output
      }
    end

    it 'returns the output from the command' do
      subject.send(:process, 'the command', **args, &blk).should ==
        result
    end
  end
end
