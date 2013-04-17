require 'spec_helper'
require 'rosh/host/shells/base'


describe Rosh::Host::Shells::Base do
  subject do
    Rosh::Host::Shells::Base.new
  end

  its(:history) { should eq [] }
end
