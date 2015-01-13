require File.expand_path( "../lib/statistrano/version", __FILE__ )

Gem::Specification.new do |s|

  s.name          = 'statistrano'
  s.version       = Statistrano::VERSION
  s.platform      = Gem::Platform::RUBY

  s.summary       = 'deployment tool for static sites'
  s.description   = %q{ Deployment tool focused on static sites. Has different modes for releases with rollbacks, or for multiple branches allowing rapid prototyping. }
  s.authors       = ["Jordan Andree", "Steven Sloan"]
  s.email         = "marketing-dev@mailchimp.com"
  s.homepage      = "http://github.com/mailchimp/statistrano"
  s.license       = "New-BSD"

  s.files         = Dir[ "{doc,lib}/**/*", "readme.md", "changelog.md" ]
  s.test_files    = Dir["spec/**/*.rb"]
  s.require_path  = "lib"

  # Utility
  s.add_dependency "rake",          ["~> 10.0"]
  s.add_dependency "rainbow",       [">=  1.99", "< 2.1"]
  s.add_dependency "slugity",       ["~>  1.0"]
  s.add_dependency "here_or_there", ["~>  0.2"]
  s.add_dependency "asgit",         ["~>  0.1"]

end
