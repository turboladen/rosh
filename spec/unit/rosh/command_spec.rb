require 'rosh/command'

RSpec.describe Rosh::Command do
  subject do
    Object.new.extend(described_class)
  end

  describe '#run_command' do
    let(:host) { double 'Rosh::Host' }
    before { allow(subject).to receive(:current_host) { host } }

    context 'idempotent_mode is true' do
      before { allow(host).to receive(:idempotent_mode?) { true } }
      let(:result) { double 'Rosh::PrivateCommandResult' }

      context 'if_any is true' do
        it 'runs the command' do
          expect(subject).to receive(:publish)
          expect(result).to receive(:ruby_object)
          subject.run_command(if_any: -> { true }) { result }
        end
      end

      context 'if_any is false' do
        it 'does not run the command' do
          expect(subject).to_not receive(:publish)
          expect(result).to_not receive(:ruby_object)
          subject.run_command(if_any: -> { false }) { result }
        end
      end

      context 'if_all is true' do
        it 'runs the command' do
          expect(subject).to receive(:publish)
          expect(result).to receive(:ruby_object)
          subject.run_command(if_all: -> { true }) { result }
        end
      end

      context 'unless_all is false' do
        it 'runs the command' do
          expect(subject).to receive(:publish)
          expect(result).to receive(:ruby_object)
          subject.run_command(unless_all: -> { false }) { result }
        end
      end

      context 'unless_all is true' do
        it 'does not run the command' do
          expect(subject).to_not receive(:publish)
          expect(result).to_not receive(:ruby_object)
          subject.run_command(unless_all: -> { true }) { result }
        end
      end

      context 'if_all is false' do
        it 'does not run the command' do
          expect(subject).to_not receive(:publish)
          expect(result).to_not receive(:ruby_object)
          subject.run_command(if_all: -> { false }) { result }
        end
      end
    end
  end

  describe '#all_true?' do
    context 'array of procs that each return true' do
      let(:criteria) { [-> { true }, -> { true }] }

      it 'returns true' do
        expect(subject.send(:all_true?, criteria)).to eq true
      end
    end

    context 'array of procs that one returns false' do
      let(:criteria) { [-> { false }, -> { true }] }

      it 'returns false' do
        expect(subject.send(:all_true?, criteria)).to eq false
      end
    end

    context 'array of procs that all return false' do
      let(:criteria) { [-> { false }, -> { false }] }

      it 'returns false' do
        expect(subject.send(:all_true?, criteria)).to eq false
      end
    end

    context 'single proc that returns true' do
      let(:criteria) { -> { true } }

      it 'returns true' do
        expect(subject.send(:all_true?, criteria)).to eq true
      end
    end

    context 'single proc that returns false' do
      let(:criteria) { -> { false } }

      it 'returns false' do
        expect(subject.send(:all_true?, criteria)).to eq false
      end
    end

    context 'statement that evaluates to true' do
      let(:criteria) { true }

      it 'returns true' do
        expect(subject.send(:all_true?, criteria)).to eq true
      end
    end

    context 'statement that evaluates to false' do
      let(:criteria) { false }

      it 'returns true' do
        expect(subject.send(:all_true?, criteria)).to eq false
      end
    end
  end

  describe '#any_true?' do
    context 'array of procs that each return true' do
      let(:criteria) { [-> { true }, -> { true }] }

      it 'returns true' do
        expect(subject.send(:any_true?, criteria)).to eq true
      end
    end

    context 'array of procs that one returns false' do
      let(:criteria) { [-> { false }, -> { true }] }

      it 'returns true' do
        expect(subject.send(:any_true?, criteria)).to eq true
      end
    end

    context 'array of procs that all return false' do
      let(:criteria) { [-> { false }, -> { false }] }

      it 'returns false' do
        expect(subject.send(:any_true?, criteria)).to eq false
      end
    end

    context 'single proc that returns true' do
      let(:criteria) { -> { true } }

      it 'returns true' do
        expect(subject.send(:any_true?, criteria)).to eq true
      end
    end

    context 'single proc that returns false' do
      let(:criteria) { -> { false } }

      it 'returns false' do
        expect(subject.send(:any_true?, criteria)).to eq false
      end
    end

    context 'statement that evaluates to true' do
      let(:criteria) { true }

      it 'returns true' do
        expect(subject.send(:any_true?, criteria)).to eq true
      end
    end

    context 'statement that evaluates to false' do
      let(:criteria) { false }

      it 'returns false' do
        expect(subject.send(:any_true?, criteria)).to eq false
      end
    end
  end
end
