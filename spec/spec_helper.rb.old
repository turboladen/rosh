require 'simplecov'

SimpleCov.start do
  add_filter '/spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
Dir['spec/support/**/*.rb'].each { |f| require File.expand_path(f) }

RSpec.configure do |config|
  def config.escaped_path(*parts)
    Regexp.compile(parts.join('[\\\/]') + '[\\\/]')
  end

  config.include Rosh::FunctionalExampleGroup, type: :functional, example_group: {
    file_path: config.escaped_path(%w[spec functional])
  }
  config.include Rosh::UnitExampleGroup, type: :unit, example_group: {
    file_path: config.escaped_path(%w[spec unit])
  }
end

