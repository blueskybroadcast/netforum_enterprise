# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'netforum_enterprise/version'

Gem::Specification.new do |spec|
  spec.name          = "netforum_enterprise"
  spec.version       = NetforumEnterprise::VERSION
  spec.authors       = ["Marc Villanueva", "Timm Liu"]
  spec.email         = ["mvillanueva@blueskybroadcast.com", "tliu@blueskybroadcast.com"]
  spec.summary       = %q{Gem for interacting with Avectra's Netforum Enterprise API.}
  spec.description   = %q{Gem for interacting with Avectra's Netforum Enterprise API.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "savon", "~> 2.11.1"
  spec.add_dependency "httpclient"
  spec.add_dependency "hashie"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'byebug'
end
