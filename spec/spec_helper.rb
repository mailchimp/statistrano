require 'rspec'
require 'pry-debugger'
require 'statistrano'


def pick_fixture name
  root = Dir.pwd
  Dir.chdir( File.join( root, "fixture", name ) )
end