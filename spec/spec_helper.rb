require 'rspec'
require 'pry-debugger'
require 'statistrano'
require 'fileutils'
require 'timecop'


ROOT = Dir.pwd

def pick_fixture name
  Dir.chdir( File.join( ROOT, "fixture", name ) )
end

def cleanup_fixture
  FileUtils.rm_rf File.join( Dir.getwd, "deployment" )
  Dir.chdir( ROOT )
end