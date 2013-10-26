require './lib/rosh/version'


Gem::Specification.new do |s|
  s.name = 'rosh'
  s.version = Rosh::VERSION
  s.author = 'Steve Loveless'
  s.homepage = 'http://github.com/turboladen/rosh'
  s.email = 'steve.loveless@gmail.com'
  s.summary = "FIX"
  s.description = %q(FIX)

  s.required_rubygems_version = '>=1.8.0'
  s.files = Dir.glob('{lib,spec}/**/*') + Dir.glob('*.rdoc') +
    %w(.gemtest Gemfile rosh.gemspec Rakefile)
  s.test_files = Dir.glob('{spec}/**/*')
  s.require_paths = %w[lib]

  s.add_dependency 'awesome_print'
  s.add_dependency 'colorize'
  s.add_dependency 'highline'
  s.add_dependency 'log_switch'
  s.add_dependency 'plist'
  s.add_dependency 'net-ssh'
  s.add_dependency 'net-scp'
  s.add_dependency 'sys-proctable'

  s.add_development_dependency 'aruba'
  s.add_development_dependency 'bundler', '>= 1.0.1'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'memfs'
  s.add_development_dependency 'rspec', '>= 2.12.0'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'yard', '>= 0.7.2'
end
