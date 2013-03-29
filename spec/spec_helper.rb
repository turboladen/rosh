require 'simplecov'

SimpleCov.start do
  add_filter '/spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')

