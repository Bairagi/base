# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'goatos/version'

Gem::Specification.new do |spec|
  spec.name          = 'goatos-base'
  spec.version       = GoatOS::VERSION.dup
  spec.authors       = ['Rnjib Dey']
  spec.email         = ['dey.ranjib@gmail.com']
  spec.summary       = %q{LXC automation suite}
  spec.description   = %q{Automate LXC with Chef}
  spec.homepage      = 'https://github.com/goatos/base'
  spec.license       = 'Apache'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'chef'
  spec.add_dependency 'blender'
  spec.add_dependency 'blender-chef'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'yard'
end
