# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sfrp/version'

Gem::Specification.new do |spec|
  spec.name          = "sfrp"
  spec.version       = SFRP::VERSION
  spec.authors       = ["Kensuke Sawada"]
  spec.email         = ["sasasawada@gmail.com"]
  spec.summary       =
    %q{Compiler of a pure functional language for microcontrollers.}
  spec.description   = %q{Pure Functional Language for microcontrollers.}
  spec.homepage      = "https://github.com/sfrp/sfrp"
  spec.license       = "The BSD 3-Clause License"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  # testing
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'

  # code analyzing
  spec.add_development_dependency 'rubocop', '0.40.0'

  # debugging
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'tapp'
  spec.add_development_dependency 'awesome_print'

  # parsing
  spec.add_dependency "parslet", "1.7.1"
end
