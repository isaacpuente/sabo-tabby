lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "sabo_tabby/version"

Gem::Specification.new do |spec|
  spec.name          = "sabo-tabby"
  spec.version       = SaboTabby::VERSION
  spec.authors       = ["Boris Huskic"]
  spec.email         = ["bhuskic@gmail.com"]

  spec.summary       = "JsonApi serializer"
  spec.description   = spec.summary
  #spec.homepage      = 'https://github.com/'
  #spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|bin)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w(. lib)
  spec.required_ruby_version = ">= 2.6.1"
  spec.add_runtime_dependency "dry-initializer"
  spec.add_runtime_dependency "dry-system"
  spec.add_runtime_dependency "concurrent-ruby", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 2.x"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 0.52.1"
end
