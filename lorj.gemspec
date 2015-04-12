# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lorj/version'

require 'rbconfig'
ruby_conf = defined?(RbConfig) ? RbConfig::CONFIG : Config::CONFIG
less_than_one_nine = ruby_conf['MAJOR'].to_i == 1 && ruby_conf['MINOR'].to_i < 9
less_than_two = ruby_conf['MAJOR'].to_i < 2

Gem::Specification.new do |spec|
  spec.name          = 'lorj'
  spec.version       = Lorj::VERSION
  spec.authors       = ['forj team']
  spec.email         = ['forj@forj.io']
  spec.summary       = 'Process Controllers framework system'
  spec.description   = <<-END
  Framework to create/maintain uniform process, against any kind of controller.
  This library is used by forj to become cloud agnostic.
  END
  spec.homepage      = 'https://github.com/forj-oss/lorj'
  spec.license       = 'Apache License, Version 2.0.'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'rubocop', '>= 0.29.0'
  spec.add_development_dependency 'byebug' unless less_than_two
  spec.rdoc_options << \
    '--title Lorj - The Process Controllers framework system' << \
    '--main README.md'

  spec.add_runtime_dependency 'config_layers', '~>0.1.0'
  #  spec.add_runtime_dependency 'git', '>=1.2.7'
  #  spec.add_runtime_dependency 'rbx-require-relative', '~>0.0.7'
  spec.add_runtime_dependency 'highline', '~> 1.6.21'
  spec.add_runtime_dependency 'ansi', '>= 1.4.3'
  #  spec.add_runtime_dependency 'bundler'
  spec.add_runtime_dependency 'encryptor', '1.3.0'
  #  spec.add_runtime_dependency 'json', '1.7.5'
end
