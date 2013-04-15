require 'spec_helper'
require 'rosh/host/attributes'


describe Rosh::Host::Attributes do
  let(:hostname) { 'test' }
  let(:shell) { double 'Rosh::Shell' }

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
    let(:result) { double 'Rosh::CommandResult' }

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
      let(:msg) do
        'Darwin computer.local 12.3.0 Darwin Kernel Version 12.3.0: Sun Jan  6 22:37:10 PST 2013; root:xnu-2050.22.13~1/RELEASE_X86_64 x86_64'
      end

      it 'sets @operating_system, @kernel_version, and @architecture' do
        subject.send(:extract_os, msg)
        subject.instance_variable_get(:@operating_system).should == :darwin
        subject.instance_variable_get(:@kernel_version).should == '12.3.0'
        subject.instance_variable_get(:@architecture).should == :x86_64
      end
    end

    context 'linux' do
      let(:msg) do
        'Linux debian 2.6.24-1-686 #1 SMP Thu May 8 02:16:39 UTC 2008 i686 '
      end

      it 'sets @operating_system, @kernel_version, and @architecture' do
        subject.send(:extract_os, msg)
        subject.instance_variable_get(:@operating_system).should == :linux
        subject.instance_variable_get(:@kernel_version).should == '2.6.24-1-686'
        subject.instance_variable_get(:@architecture).should == :i686
      end
    end

    context 'freebsd' do
      let(:msg) do
        'FreeBSD sloveless-fbsd 9.1-RELEASE FreeBSD 9.1-RELEASE #0 r243825: Tue Dec  4 09:23:10 UTC 2012     root@farrell.cse.buffalo.edu:/usr/obj/usr/src/sys/GENERIC  amd64'
      end

      it 'sets @operating_system, @kernel_version, and @architecture' do
        subject.send(:extract_os, msg)
        subject.instance_variable_get(:@operating_system).should == :freebsd
        subject.instance_variable_get(:@kernel_version).should == '9.1-RELEASE'
        subject.instance_variable_get(:@architecture).should == :amd64
      end
    end
  end

  describe '#extract_distribution' do
    context 'darwin' do
      let(:msg) do
        msg = <<-MSG
ProductName:	Mac OS X
ProductVersion:	10.8.3
BuildVersion:	12D78
        MSG
      end

      before do
        subject.instance_variable_set(:@operating_system, :darwin)
      end

      it 'sets @distribution and @distribution_version' do
        subject.send(:extract_distribution, msg)
        subject.instance_variable_get(:@distribution).should == :mac_os_x
        subject.instance_variable_get(:@distribution_version).should == '10.8.3'
      end
    end

    context 'linux' do
      let(:msg) do
        'Description:	Ubuntu 12.04.2 LTS'
      end

      before do
        subject.instance_variable_set(:@operating_system, :linux)
      end

      it 'sets @distribution and @distribution_version' do
        subject.send(:extract_distribution, msg)
        subject.instance_variable_get(:@distribution).should == :ubuntu
        subject.instance_variable_get(:@distribution_version).should == '12.04.2 LTS'
      end
    end
  end
end
