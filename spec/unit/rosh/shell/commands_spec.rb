require 'rosh/shell/commands'

RSpec.describe Rosh::Shell::Commands do
  subject(:shell) do
    Object.new.extend(described_class)
  end

  let(:current_host) do
    double 'Rosh::Host'
  end

  before do
    allow(shell).to receive(:current_host) { current_host }
  end

  describe '#cat' do
    before do
      current_host.stub_chain(:fs, :[]) { file }
    end

    let(:file) do
      double 'Rosh::FileSystem::File'
    end

    it 'outputs that it is running the command' do
      expect(shell).to receive(:echo_rosh_command).with('file')
      allow(shell).to receive(:process)

      subject.cat 'file'
    end

    context 'file exists' do
      it 'gets the contents of the file via the file system' do
        allow(subject).to receive(:echo_rosh_command)
        expect(subject).to receive(:process).with(:cat, file: 'file').and_yield
        expect(file).to receive(:contents) { 'contents' }

        expect(subject.cat('file')).to eq ['contents', 0]
      end
    end

    context 'file does not exist' do
      it 'returns a Rosh::ErrorENOENT and 127' do
        allow(subject).to receive(:echo_rosh_command)
        expect(subject).to receive(:process).with(:cat, file: 'file').and_yield
        expect(file).to receive(:contents).and_raise Rosh::ErrorENOENT

        output = subject.cat 'file'
        expect(output.first).to be_a Rosh::ErrorENOENT
        expect(output.last).to eq 127
      end
    end

    context 'file given is a directory' do
      it 'returns a Rosh::ErrorEISDIR and 1' do
        allow(subject).to receive(:echo_rosh_command)
        expect(subject).to receive(:process).with(:cat, file: 'file').and_yield
        expect(file).to receive(:contents).and_raise Rosh::ErrorEISDIR

        output = subject.cat 'file'
        expect(output.first).to be_a Rosh::ErrorEISDIR
        expect(output.last).to eq 1
      end
    end
  end
end
