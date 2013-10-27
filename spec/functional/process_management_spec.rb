require 'spec_helper'
require 'rosh'


shared_examples_for 'a process manager' do
  it 'can list processes' do
    list = host.processes.list

    list.each do |host_process|
      expect(host_process.class).to eq Rosh::ProcessManager::Process
    end
  end

  it 'can list supported signals' do
    list = host.processes.supported_signals
    expect(list).to be_an Hash

    list.each do |name, value|
      expect(name).to be_a String
      expect(value).to be_a Fixnum
    end
  end

  it 'can send a signal to a process' do
    host.su do
      host.processes.list.first.send_signal 'USR1'
    end
  end
end

describe 'Process Management' do
  include_context 'hosts'

  context 'centos' do
    it_behaves_like 'a process manager' do
      let(:host) { Rosh.hosts[:centos_57_64] }
    end
  end

  context 'debian' do
    it_behaves_like 'a process manager' do
      let(:host) { Rosh.hosts[:debian_squeeze_32] }
    end
  end
end
