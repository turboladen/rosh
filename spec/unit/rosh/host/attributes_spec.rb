require 'spec_helper'
require 'rosh/host/attributes'


describe Rosh::Host::Attributes do
  let(:hostname) { 'test' }
  let(:shell) { double 'Rosh::Shell' }
  let(:result) { double 'Rosh::CommandResult' }

  before do
    subject.instance_variable_set(:@shell, shell)
    subject.stub(:log)
  end

  subject do
    o = Object.new
    o.extend Rosh::Host::Attributes

    o
  end

  describe '#remote_shell' do
    before do
      result.stub_chain(:ssh_result, :stdout).and_return hostname
    end

    it 'runs "echo $SHELL" and returns the output as a Symbol' do
      shell.should_receive(:exec).with('echo $SHELL').and_return result
      subject.remote_shell.should == :test
    end
  end

  describe '#extract_os' do
    context 'darwin' do
      before do
        msg = 'Darwin computer.local 12.3.0 Darwin Kernel Version 12.3.0: Sun Jan  6 22:37:10 PST 2013; root:xnu-2050.22.13~1/RELEASE_X86_64 x86_64'
        result.stub(:ruby_object).and_return(msg)
      end

      it 'sets @operating_system, @kernel_version, and @architecture' do
        subject.send(:extract_os, result)
        subject.instance_variable_get(:@operating_system).should == :darwin
        subject.instance_variable_get(:@kernel_version).should == '12.3.0'
        subject.instance_variable_get(:@architecture).should == :x86_64
      end
    end

    context 'linux' do
      before do
        msg = 'Linux debian 2.6.24-1-686 #1 SMP Thu May 8 02:16:39 UTC 2008 i686 '
        result.stub(:ruby_object).and_return(msg)
      end

      it 'sets @operating_system, @kernel_version, and @architecture' do
        subject.send(:extract_os, result)
        subject.instance_variable_get(:@operating_system).should == :linux
        subject.instance_variable_get(:@kernel_version).should == '2.6.24-1-686'
        subject.instance_variable_get(:@architecture).should == :i686
      end
    end
  end

  describe '#extract_distribution' do
    context 'darwin' do
      before do
        msg = <<-MSG
ProductName:	Mac OS X
ProductVersion:	10.8.3
BuildVersion:	12D78
        MSG

        result.stub(:ruby_object).and_return(msg)
        subject.instance_variable_set(:@operating_system, :darwin)
      end

      it 'sets @distribution and @distribution_version' do
        subject.send(:extract_distribution, result)
        subject.instance_variable_get(:@distribution).should == :mac_os_x
        subject.instance_variable_get(:@distribution_version).should == '10.8.3'
      end
    end

    context 'linux' do
      before do
        msg ='Description:	Ubuntu 12.04.2 LTS'

        result.stub(:ruby_object).and_return(msg)
        subject.instance_variable_set(:@operating_system, :linux)
      end

      it 'sets @distribution and @distribution_version' do
        subject.send(:extract_distribution, result)
        subject.instance_variable_get(:@distribution).should == :ubuntu
        subject.instance_variable_get(:@distribution_version).should == '12.04.2 LTS'
      end
    end
  end
end
