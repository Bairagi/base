# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'goatos/version'

Gem::Specification.new do |spec|
  spec.name          = 'goatos-base'
  spec.version       = GoatOS::VERSION.dup
  spec.authors       = ['Ranjib Dey']
  spec.email         = ['dey.ranjib@gmail.com']
  spec.summary       = %q{Distributed LXC automation suite using Chef and Blender}
  spec.description   = %q{Deploy and manage multi node LXC installation using Chef and Blender}
  spec.homepage      = 'https://github.com/goatos/base'
  spec.license       = 'Apache'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'thor'
  spec.add_dependency 'chef'
  spec.add_dependency 'pd-blender'
  spec.add_dependency 'blender-chef'
  spec.add_dependency 'sshkey'
  spec.add_dependency 'net-scp'


  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'yard'
end
