require 'rosh/service_manager/service'

RSpec.describe Rosh::ServiceManager::Service do
  let(:shell) { double 'Rosh::Host::Shell' }

  before do
    described_class.any_instance.stub(:load_adapter)
    allow(subject).to receive(:current_shell) { shell }
  end

  subject { described_class.new('thing', 'example.com') }

  describe '#build_info' do
    context 'only status is given' do
      context 'no process info available' do
        before do
          shell.should_receive(:ps).with(name: 'thing').and_return []
        end

        it 'returns a Hash with name and status set' do
          subject.send(:build_info, :meow).should == {
            name: 'thing',
            status: :meow,
            processes: []
          }
        end
      end

      context 'process info available' do
        it 'returns a Hash with name, passed in status, and processes set' do
          shell.should_receive(:ps).with(name: 'thing').and_return ['process info']

          subject.send(:build_info, :meow).should == {
            name: 'thing',
            status: :meow,
            processes: ['process info']
          }
        end
      end
    end

    context 'pid is given' do
      context 'process info is found for pid' do
        it 'returns a Hash with name, status = :running, and processes set' do
          shell.should_receive(:ps).with(pid: 1).and_return ['process info']

          subject.send(:build_info, :meow, pid: 1).should == {
            name: 'thing',
            status: :running,
            processes: ['process info']
          }
        end
      end

      context 'process info is not found for pid' do
        it 'returns a Hash with name, passed in status set' do
          shell.should_receive(:ps).with(pid: 1).and_return []

          subject.send(:build_info, :meow, pid: 1).should == {
            name: 'thing',
            status: :meow,
            processes: []
          }
        end
      end
    end

    context 'process_info is given' do
      it 'returns a Hash with name, passed in status, and processes set' do
        shell.should_not_receive(:ps)

        subject.send(:build_info, :meow, process_info: %w[info]).should == {
          name: 'thing',
          status: :meow,
          processes: %w[info]
        }
      end
    end
  end
end
