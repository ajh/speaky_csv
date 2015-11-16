# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'speaky_csv/version'

Gem::Specification.new do |spec|
  spec.name          = 'speaky_csv'
  spec.version       = SpeakyCsv::VERSION
  spec.authors       = ['Andrew Hartford']
  spec.email         = ['andrew.hartford@doxo.com']
  spec.summary       = 'some summary'
  spec.description   = 'som description'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'activemodel'
  spec.add_runtime_dependency 'activerecord'

  spec.add_development_dependency 'bundler', '> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '> 2.14.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'database_cleaner'

  # guard stuff
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rb-fsevent'
  spec.add_development_dependency 'rb-inotify'
  spec.add_development_dependency 'ruby_gntp'
end
