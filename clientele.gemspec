# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'clientele/version'

Gem::Specification.new do |spec|
  spec.name          = "clientele"
  spec.version       = Clientele::VERSION
  spec.authors       = ["Chris Keele"]
  spec.email         = ["dev@chriskeele.com"]
  spec.summary       = 'An HTTP client library for the discerning rubyist.'
  spec.description   = <<-DESC
  DESC
  spec.homepage      = "https://github.com/christhekeele/clientele"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.0'

  spec.add_runtime_dependency "clientele-http", "~> 0.1"
  spec.add_runtime_dependency "clientele-utils", "~> 0.1"
  spec.add_runtime_dependency "addressable", "~> 2.4.0"

  spec.add_development_dependency "bundler", "> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec",   "~> 3.0"
end
