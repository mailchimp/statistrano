require File.expand_path( "../lib/statistrano/version", __FILE__ )

Gem::Specification.new do |s|

  s.name          = 'statistrano'
  s.version       = Statistrano::VERSION
  s.platform      = Gem::Platform::RUBY

  s.summary       = 'A simplified deployments for static sites'
  s.description   = %q{ Simplified the deployment of static sites, releases if you'd like, and features for staging feature branches }
  s.authors       = ["Jordan Andree", "Steven Sloan"]
  s.email         = "marketing-dev@mailchimp.com"
  s.homepage      = "http://github.com/stevenosloan/statistrano"

  s.files         = Dir["{lib}/**/*.rb"]
  s.test_files    = Dir["spec/**/*.rb"]
  s.require_path  = "lib"

  # Utility
  s.add_dependency "rake",          ["~> 10.0"]
  s.add_dependency "rainbow",       ["~>  1.99"]
  s.add_dependency "slugity",       ["~>  1.0"]
  s.add_dependency "here_or_there", ["~>  0.1"]
  s.add_dependency "asgit",         ["~>  0.1"]

end