# -*- ruby -*-

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

desc 'Run Rosh in the console'
task :console do
  require 'irb'
  require 'irb/completion'
  require './lib/rosh' # You know what to do.
  ARGV.clear
  IRB.start
end

YARD::Rake::YardocTask.new do |t|
  t.files = %w(lib/**/*.rb - History.md)
  t.options = %W(--title rosh Documentation (#{Rosh::VERSION}))
  t.options += %w(--main README.md)
end

namespace :spec do
  desc 'Run RSpec unit code examples'
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.ruby_opts = %w(-w)
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

  desc 'Run RSpec functional code examples'
  RSpec::Core::RakeTask.new(:functional) do |t|
    t.ruby_opts = %w(-w)
    t.pattern = 'spec/functional/**/*_spec.rb'
  end

  desc 'Run all RSpec code examples'
  RSpec::Core::RakeTask.new(:all) do |t|
    t.ruby_opts = %w(-w)
  end
end

desc 'Run RSpec unit code examples'
task spec: 'spec:unit'

# Alias for rubygems-test
task test: :spec

# vim: syntax=ruby
