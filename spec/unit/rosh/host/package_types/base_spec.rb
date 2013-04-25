require 'spec_helper'
require 'rosh/host/package_types/base'


describe Rosh::Host::PackageTypes::Base do
  let(:shell) do
    double 'Rosh::Host::Shell'
  end

  subject do
    Rosh::Host::PackageTypes::Base.new('test', shell, version: '1', status: 'ok')
  end

  its(:name) { should eq 'test' }
  its(:version) { should eq '1' }
  its(:status) { should eq 'ok' }
end
