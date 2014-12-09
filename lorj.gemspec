# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lorj/version'

Gem::Specification.new do |spec|
  spec.name          = "lorj"
  spec.version       = Lorj::VERSION
  spec.authors       = ["forj team"]
  spec.email         = ["forj@forj.io"]
  spec.summary       = %q{Process Controllers framework system}
  spec.description   = %q{Framework to create/maintain uniform process, against any kind of controller.}
  spec.homepage      = "https://github.com/forj-oss/lorj"
  spec.license       = "Apache License, Version 2.0."

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.1.0"
  spec.rdoc_options << '--title' << 'Lorj - The Process Controllers framework system' <<
  '--main' << 'README.md'

#  spec.add_runtime_dependency 'thor', '~>0.16.0'
#  spec.add_runtime_dependency 'nokogiri', '~>1.5.11'
#  spec.add_runtime_dependency 'fog', '~>1.19.0'
#  spec.add_runtime_dependency 'hpcloud', '~>2.0.9'
#  spec.add_runtime_dependency 'git', '>=1.2.7'
#  spec.add_runtime_dependency 'rbx-require-relative', '~>0.0.7'
#  spec.add_runtime_dependency 'highline', '~> 1.6.21'
  spec.add_runtime_dependency 'ansi', '>= 1.4.3'
#  spec.add_runtime_dependency 'bundler'
#  spec.add_runtime_dependency 'encryptor', '1.3.0'
#  spec.add_runtime_dependency 'json', '1.7.5'

end
