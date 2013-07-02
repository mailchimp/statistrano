require 'simplecov'
SimpleCov.start

require 'rspec'
require 'pry-debugger'
require 'statistrano'
require 'fileutils'

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

def release_folder_contents
  Dir[ "deployment/releases/**" ].map { |d| d.gsub("deployment/releases/", '' ) }
end

def deployment_folder_contents
  Dir[ "deployment/**" ].map { |d| d.gsub("deployment/", '' ) }
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


#     Patches STDIN for a block
# ----------------------------------------------------

def fake_stdin(*args)
  begin
    $stdin = StringIO.new
    $stdin.puts(args.shift) until args.empty?
    $stdin.rewind
    yield
  ensure
    $stdin = STDIN
  end
end


#     Patches STDOUT for Shell.run
# ----------------------------------------------------

def fake_stdout out
  begin
    Statistrano::Shell.set_stdout out
    yield
  ensure
    Statistrano::Shell.unset_stdout
  end
end

def fake_stderr err
  begin
    Statistrano::Shell.set_stderr err
    yield
  ensure
    Statistrano::Shell.unset_stderr
  end
end


module Statistrano
  module Shell
    class << self
      def patched_run command, &block
        if @shell_out || @shell_err
          yield @shell_out if block_given?
          [ true, @shell_out, @shell_err ]
        else
          system_run command, &block
        end
      end

      def set_stdout out
        @shell_out = out
      end

      def unset_stdout
        @shell_out = nil
      end

      def set_stderr err
        @shell_err = err
      end

      def unset_stderr
        @shell_err = nil
      end

      alias_method :system_run, :run
      alias_method :run, :patched_run
    end
  end
end