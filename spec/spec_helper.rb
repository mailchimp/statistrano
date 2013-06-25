require 'rspec'
require 'pry-debugger'
require 'statistrano'
require 'fileutils'
require 'timecop'

# for eating up stdout
output = StringIO.open('','w+')
$stdout = output

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

include ::Rake::DSL
namespace :remote do
  task :copy do
    `cp -r source/ build/ 2> /dev/null`
  end
  task :error do
    raise "error during the build"
  end
end

def reenable_rake_tasks
  Rake::Task.tasks.each { |t| t.reenable }
end

#     Monkey Patch Time
# ----------------------------------------------------

class Time
  class << self
    def frozen_now
      @now || advancing_now
    end

    def static_time= time
      @now = time
    end

    def thaw
      @now = nil
    end

    alias_method :advancing_now, :now
    alias_method :now, :frozen_now
  end
end

def set_time out
  Time.static_time = Time.at(out)
end


#     Monkey Patch Stat::Git
# ----------------------------------------------------

module Statistrano
  module Git
    class << self
      def set_branch branch
        @branch = branch
      end
      def static_branch
        @branch || live_branch
      end
      def unset_branch
        @branch = nil
      end

      alias_method :live_branch, :current_branch
      alias_method :current_branch, :static_branch
    end
  end
end