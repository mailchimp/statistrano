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

def tracer msg
  STDOUT.puts "\n\n==========================\n\n#{msg}\n\n==========================\n"
end

module PatchTime
  class Time
    def self.now
      @now || TIME
    end

    def self.now= time
      @now = time
    end
  end

  def set_time out
    Time.now = Time.at(out)
  end
end