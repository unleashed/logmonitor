# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'logmonitor'
  spec.version       = '1.0'
  spec.authors       = ["Alejandro Martinez Ruiz"]
  spec.email         = ['unledev@gmail.com']
  spec.description   = %q{A simple HTTP log monitor}
  spec.summary       = %q{A simple HTTP log monitor}
  spec.homepage      = ""
  spec.license       = "Public domain"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
