require File.expand_path( "../lib/statistrano/version", __FILE__ )

Gem::Specification.new do |s|

  s.name          = 'statistrano'
  s.version       = Statistrano::VERSION
  s.platform      = Gem::Platform::RUBY

  s.summary       = 'XX'
  s.description   = %q{ XX }
  s.authors       = ["Jordan Andree", "Steven Sloan"]
  s.email         = ["xx@xx.com", "stevenosloan@gmail.com"]
  s.homepage      = "http://github.com/stevenosloan/statistrano"

  s.files         = Dir["{lib}/**/*.rb"]
  s.test_files    = Dir["spec/**/*.rb"]
  s.require_path  = "lib"

  # Utility
  s.add_dependency("rake", ["~> 10.0.3"])
  s.add_dependency("colorize", ["~> 0.5.8"])

  # Networking
  s.add_dependency("net-ssh", ["~> 2.6.5"])

  # CLI
  s.add_dependency("thor", ["~> 0.15.4"])

end