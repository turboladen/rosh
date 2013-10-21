require 'spec_helper'
require 'rosh/host/shells/local'
require 'tempfile'


describe Rosh::Host::Shells::Local do
  subject do
    Rosh::Host::Shells::Local.new
  end

  describe '#cd' do
    context 'directory does not exist' do
      before { @r = subject.cd('blah') }

      specify { @r.should be_a Errno::ENOENT }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'directory is a file' do
      before do
        Dir.should_receive(:chdir).with(File.expand_path('blah')).
          and_raise Errno::ENOTDIR

        @r = subject.cd('blah')
      end

      specify { @r.should be_a Errno::ENOTDIR }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'directory exists' do
      before { @r = subject.cd('/') }

      specify { @r.should be_true }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }
    end
  end

  describe '#exec' do
    context 'invalid command' do
      before do
        PTY.should_receive(:spawn).and_raise
        @r = subject.exec('bskldfjlsk')
      end

      specify { @r.should be_kind_of Exception }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'valid command' do
      let(:reader) do
        r = double 'PTY reader'
        r.should_receive(:readpartial).and_return 'command output'
        r.should_receive(:readpartial).and_raise EOFError

        r
      end

      before do
        PTY.should_receive(:spawn).and_yield reader, nil, 123
        Process.should_receive(:wait).with(123)
        @r = subject.exec('ls')
      end

      specify { @r.should eq 'command output' }
      specify { pending; subject.last_exit_status.should eq $?.exitstatus }
      specify { subject.last_result.should eq @r }
    end
  end

  describe '#pwd' do
    let(:output) { double 'output', to_s: 'the dir' }

    before do
      expect(subject).to receive(:process).with(:pwd) { output }
      @r = subject.pwd
    end

    specify { expect(@r).to eq output  }
  end

  describe '#ruby' do
    context 'the executed code raises an exception' do
      before { @r = subject.ruby 'raise' }

      specify { @r.should be_a RuntimeError }
      specify { subject.last_exit_status.should eq 1 }
      specify { subject.last_result.should eq @r }
    end

    context 'the executed code saves a value to a variable' do
      before { @r = subject.ruby 'var = [1, 2, 3]' }

      specify { @r.should eq [1, 2, 3] }
      specify { subject.last_exit_status.should eq 0 }
      specify { subject.last_result.should eq @r }

      it 'allows subsequent #ruby calls to access that saved variable' do
        expect { subject.ruby 'var' }.to_not raise_exception
      end
    end
  end
end
