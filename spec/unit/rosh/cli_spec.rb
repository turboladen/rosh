require 'spec_helper'
require 'rosh/cli'


describe Rosh::CLI do
  before do
    Rosh::CLI.stub :log
  end

  describe '#run' do
    let(:prompt) { double 'prompt' }

    before do
      subject.stub(:loop).and_yield
      subject.stub(:new_prompt).and_return prompt
    end

    it "saves commands to Readline's history" do
      subject.should_receive(:readline).with(prompt, true).and_return ''
      subject.run
    end

    context 'multiline ruby' do
      before do
        subject.should_receive(:multiline_ruby?).and_return true
        subject.stub(:readline).and_return 'loop do'
      end

      it 'calls #ruby_prompt, appends the output to argv, and executes that' do
        subject.should_receive(:ruby_prompt).with('loop do').
          and_return("loop do\nend")
        subject.should_receive(:execute).with("loop do\nend").and_return ''
        subject.stub(:print_result)
        subject.run
      end
    end

    context 'single line ruby' do
      before do
        subject.should_receive(:multiline_ruby?).and_return false
        subject.stub(:readline).and_return 'puts "hi"'
      end

      it 'executes what was passed in' do
        subject.should_not_receive(:ruby_prompt)
        subject.should_receive(:execute).with('puts "hi"').and_return ''
        subject.stub(:print_result)
        subject.run
      end
    end
  end
end
