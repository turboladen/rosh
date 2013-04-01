require 'spec_helper'
require 'fakefs/spec_helpers'
require 'rosh/shell'


describe Rosh::Shell do
  include FakeFS::SpecHelpers

  before do
    Rosh::Shell.log = false
    Rosh::Environment.stub(:path).and_return []
  end

  let(:ssh) do
    s = double 'Rosh::SSH'
    s.should_receive(:hostname).and_return 'localhost'

    s
  end

  subject { Rosh::Shell.new(ssh) }

  describe 'require' do
    it 'defines methods for each builtin command' do
      subject.should respond_to :cat, :cd, :ch, :cp, :exec, :history, :ls, :ps,
        :pwd, :ruby
    end
  end

  describe '#builtin_commands' do
    it 'returns an Array of Strings that are the built-ins' do
      subject.builtin_commands.should == %w[
        cat cd ch cp exec history ls ps pwd ruby
      ]
    end
  end

  describe '#child_files' do
    before do
      3.times do |i|
        File.open("#{i}.test", 'w') { |f| f.write 'hi' }
      end
    end

    it 'returns an Array of relative file base names' do
      subject.child_files.should == %w[0.test 1.test 2.test]
    end
  end

  describe '#path_commands' do
    before do
      3.times do |i|
        File.open("#{i}.cmd", 'w') { |f| f.write 'hi' }
      end

      Rosh::Environment.stub(:path).and_return %w[.]
    end

    it 'returns an Array of files found in Path directories' do
      subject.path_commands.should == %w[0.cmd 1.cmd 2.cmd]
    end
  end

  describe '#completions' do
    pending
  end

  describe '#store_command' do
    context 'unknown command' do
      it 'raises an error' do
        expect {
          subject.store_command('meow')
        }.to raise_error RuntimeError, "Unknown command: 'meow'"
      end
    end

    context 'no args' do
      it 'creates a new command object from the cmd name and adds it to @stored_commands' do
        expect {
          subject.store_command('ls')
        }.to change { subject.instance_variable_get(:@stored_commands).size }.by 1

        subject.instance_variable_get(:@stored_commands).first.
          should be_a Rosh::BuiltinCommands::Ls
      end
    end

    context 'with args' do
      it 'creates a new command object from the cmd name and adds it to @stored_commands' do
        expect {
          subject.store_command('ls', '/')
        }.to change { subject.instance_variable_get(:@stored_commands).size }.by 1

        subject.instance_variable_get(:@stored_commands).first.
          should be_a Rosh::BuiltinCommands::Ls
      end
    end
  end

  describe '#exec_stored' do
    context 'block given' do
      pending 'Working more with screenplay'

      before do
        subject.instance_variable_set(:@stored_commands)
      end
    end
  end
end
