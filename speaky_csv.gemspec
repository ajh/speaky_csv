# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'speaky_csv/version'

Gem::Specification.new do |spec|
  spec.name          = 'speaky_csv'
  spec.version       = SpeakyCsv::VERSION
  spec.authors       = ['Andy Hartford']
  spec.email         = ['andy.hartford@cohealo.com']
  spec.summary       = 'CSV importing and exporting for ActiveRecord and ActiveModel'
  spec.description   = 'CSV importing and exporting for ActiveRecord and ActiveModel with a Enumerator flavor'
  spec.homepage      = 'https://github.com/ajh/speaky_csv'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activemodel',    '~> 4.2'
  spec.add_runtime_dependency 'activerecord',   '~> 4.2'
  spec.add_runtime_dependency 'activesupport',  '~> 4.2'

  spec.add_development_dependency 'bundler',           '~> 1.10'
  spec.add_development_dependency 'database_cleaner',  '~> 1.5'
  spec.add_development_dependency 'rake',              '~> 10.0'
  spec.add_development_dependency 'rspec',             '~> 3'
  spec.add_development_dependency 'rspec-its',         '~> 1'
  spec.add_development_dependency 'rubocop',           '~> 0.35'
  spec.add_development_dependency 'sqlite3',           '~> 1.3'

  # guard stuff
  spec.add_development_dependency 'guard-rspec',  '~> 4.6'
  spec.add_development_dependency 'rb-fsevent',   '~> 0.9'
  spec.add_development_dependency 'rb-inotify',   '~> 0.9'
  spec.add_development_dependency 'ruby_gntp',    '~> 0.3'
end
