require 'spec_helper'
require 'rosh/host/service_types/base'


describe Rosh::Host::ServiceTypes::Base do
  let(:name) { 'thing' }
  let(:shell) { double 'Rosh::Host::Shell' }
  subject { Rosh::Host::ServiceTypes::Base.new(name, shell) }

  describe '#info' do
    specify { subject.should respond_to :info }
  end

  describe '#status' do
    specify { subject.should respond_to :status }
  end

  describe '#start' do
    specify { subject.should respond_to :start }
  end

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
