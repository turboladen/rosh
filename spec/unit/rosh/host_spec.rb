require 'spec_helper'
require 'rosh/host'


describe Rosh::Host do
  let(:name) { 'test' }

  let(:publisher) do
    Object.new.extend(DramaQueen::Producer)
  end

  subject do
    Rosh::Host.new(name)
  end

  describe '#initialize' do
    before do
      Rosh::Shell.should_receive(:new).with(name, {})
    end

    its(:name) { should eq name }
  end

  describe '#process_result' do
    let(:command_result) do
      double 'Rosh::Shell::PrivateCommandResult', string: 'hi'
    end

    it 'receives messages on "rosh.command_results"' do
      expect(subject).to receive(:log).with /hi/

      expect {
        publisher.publish 'rosh.command_results', command_result
      }.to change { subject.history.count }.by 1
    end
  end

  describe '#fs' do
    it 'subscribes to "rosh.file_system"' do
      allow(Rosh::FileSystem).to receive(:new)
      expect(subject).to receive(:subscribe).with('rosh.file_system', :update)
      subject.fs
    end
  end

  describe '#update' do
    it 'receives messages on "rosh.file_system"' do
      allow(Rosh::FileSystem).to receive(:new)
      expect(subject).to receive(:puts).with 'update called'

      subject.fs
      publisher.publish 'rosh.file_system'
    end
  end
end
