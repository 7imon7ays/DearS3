# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dears3/version'

Gem::Specification.new do |spec|
  spec.name          = "dears3"
  spec.version       = DearS3::VERSION
  spec.authors       = ["7imon7ays"]
  spec.homepage      = "https://github.com/7imon7ays/DearS3"
  spec.summary       = %q{Sync an S3 bucket with your current directory.}
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk", "~> 1.59.x"
  spec.add_dependency "oj", "~> 2.x"
  spec.add_dependency "thor", "~> 0.19.x"
  spec.add_dependency "mime-types", "2.4.3"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "byebug"
end

