# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'thrifty/version'

Gem::Specification.new do |gem|
  gem.name          = "thrifty"
  gem.version       = Thrifty::VERSION
  gem.authors       = ["Greg Brockman"]
  gem.email         = ["gdb@gregbrockman.com"]
  gem.description   = "Automatically compile Thrift definitions in Ruby"
  gem.summary       = "Begone manual compilation of Thrift definitions! Thrifty makes it easy to automatically manage your Thrift definitions."
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency 'thrift'
  gem.add_dependency 'rubysh'
end
