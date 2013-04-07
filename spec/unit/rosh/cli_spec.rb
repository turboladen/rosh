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

  describe '#execute' do
    let(:shell) do
      double 'Shell'
    end

    let(:host) do
      h = double 'Rosh::Host'
      h.stub(:shell).and_return shell

      h
    end

    before do
      subject.instance_variable_set(:@current_host, host)
      shell.should_receive(:public_methods).and_return %i[cat ls]
    end

    context 'first arg is a shell public method' do
      context 'with arguments' do
        it 'sends the command and args to the shell to run' do
          shell.should_receive(:cat).with('some_file')
          subject.execute('cat some_file')
        end
      end

      context 'without arguments' do
        it 'sends the command to the shell to run' do
          shell.should_receive(:ls).with(no_args)
          subject.execute('ls')
        end
      end
    end

    context 'first arg is a system command in the path' do
      before do
        shell.should_receive(:system_commands).and_return %w[git]
      end

      it 'sends the command and args to the shell to run using #exec' do
        shell.should_receive(:exec).with('git status')
        subject.execute('git status')
      end
    end

    context 'first arg is the absolute path to a system command' do
      before do
        shell.should_receive(:system_commands).and_return %w[/usr/local/bin/git]
      end

      it 'sends the command and args to the shell to run using #exec' do
        shell.should_receive(:exec).with('/usr/local/bin/git status')
        subject.execute('/usr/local/bin/git status')
      end
    end

    context 'command is not a method or system command' do
      before do
        shell.should_receive(:system_commands).twice.and_return []
      end

      it 'runs the command as ruby code' do
        shell.should_receive(:ruby).with 'puts "hi"'
        subject.execute 'puts "hi"'
      end
    end
  end
end
