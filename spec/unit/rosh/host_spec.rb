require 'spec_helper'
require 'rosh/host'


describe Rosh::Host do
  let(:name) { 'test' }

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
    let(:publisher) do
      Object.new.extend(DramaQueen::Producer)
    end

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
end
