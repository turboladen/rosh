require 'spec_helper'
require 'rosh/host/service_types/base'


describe Rosh::Host::ServiceTypes::Base do
  let(:name) { 'com.thing' }

  let(:shell) do
    double 'Rosh::Host::Shell'
  end

  subject do
    Rosh::Host::ServiceTypes::Base.new(name, host)
  end
end
