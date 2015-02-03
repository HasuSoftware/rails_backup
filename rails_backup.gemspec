# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rails_backup/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails_backup'
  spec.version       = RailsBackup::VERSION
  spec.authors       = ['fjsandov']
  spec.email         = ['fsandoval@hasu.cl']
  spec.summary       = 'Performs database, folders and files backup of a rails project'
  spec.description   = 'Performs database, folders and files backup using zips for compression of a rails project'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_dependency 'rubyzip', '~> 1.0.0'
  spec.add_dependency 'rails', '~> 4.0.2'
end
