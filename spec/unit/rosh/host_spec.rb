require 'rosh/host'

RSpec.describe Rosh::Host do
  let(:name) { 'test' }
  let(:publisher) { Object.new.extend(DramaQueen::Producer) }
  subject { Rosh::Host.new(name) }

  describe '#initialize' do
    before do
      Rosh::Shell.should_receive(:new).with(name, {})
    end

    specify { expect(subject.name).to eq name }
  end

  describe '#process_result' do
    let(:command_result) do
      result = double 'Result', ruby_object: 'meow'

      instance_double 'Rosh::Shell::PrivateCommandResult',
        string: 'hi'
        # string: 'hi',
        # method_arguments: [],
        # result: result
    end

    it 'receives messages on "rosh.command_results"' do
      Rosh::Logger.logging_enabled = true
      allow(subject).to receive(:log)

      expect do
        publisher.publish 'rosh.commands.test', command_result
      end.to change { subject.history.size }.by 1
    end
  end

  describe '#fs' do
    it 'subscribes to "rosh.file_system"' do
      allow(Rosh::FileSystem).to receive(:new)
      expect(subject).to receive(:subscribe).with('rosh.file_system', :update)
      subject.fs
    end
  end

  describe '#users' do
    it 'subscribes to "rosh.user_manager"' do
      allow(Rosh::UserManager).to receive(:new)
      expect(subject).to receive(:subscribe).with('rosh.user_manager', :update)
      subject.users
    end
  end

  describe '#packages' do
    it 'subscribes to "rosh.package_manager"' do
      allow(Rosh::PackageManager).to receive(:new)
      expect(subject).to receive(:subscribe).
        with('rosh.package_manager', :update)
      subject.packages
    end
  end

  describe '#processes' do
    it 'subscribes to "rosh.process_manager"' do
      allow(Rosh::ProcessManager).to receive(:new)
      expect(subject).to receive(:subscribe).
        with('rosh.process_manager', :update)
      subject.processes
    end
  end

  describe '#services' do
    it 'subscribes to "rosh.service_manager"' do
      allow(Rosh::ServiceManager).to receive(:new)
      expect(subject).to receive(:subscribe).
        with('rosh.service_manager', :update)
      subject.services
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

  describe '#local?' do
    context 'name is localhost' do
      it 'returns true' do
        subject.instance_variable_set(:@name, 'localhost')
        expect(subject).to be_local
      end
    end

    context 'name is the hostname of the localhost' do
      it 'returns true' do
        subject.instance_variable_set(:@name, Socket.gethostname)
        expect(subject).to be_local
      end
    end
  end
end
