require_relative 'spec_helper'
require 'rosh'
require 'rosh/version'

describe Rosh do
  specify { Rosh::VERSION.should == '0.1.0' }
end
