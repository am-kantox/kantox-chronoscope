# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kantox/chronoscope/version'

Gem::Specification.new do |spec|
  spec.name          = 'kantox-chronoscope'
  spec.version       = Kantox::Chronoscope::VERSION
  spec.authors       = ['Kantox']
  spec.email         = ['aleksei.matiushkin@kantox.com']

  spec.summary       = 'Handy profiler for rspec.'
  spec.description   = 'Allows to easy and quick profile method calls during rspec execution.'
  spec.homepage      = "https://github.com/am-kantox/#{spec.name}"
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  raise 'RubyGems 2.0 or newer is required.' unless spec.respond_to?(:metadata)

  # spec.metadata['allowed_push_host'] = "https://gemfury.com"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'awesome_print', '~> 1'
  spec.add_development_dependency 'codeclimate-test-reporter'

  spec.add_dependency 'kungfuig', '~> 0.7'
end
