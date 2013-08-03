require 'spec_helper'
require 'rosh/host/shells/base'


describe Rosh::Host::Shells::Base do
  subject do
    Rosh::Host::Shells::Base.new
  end

  its(:history) { should eq [] }

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
