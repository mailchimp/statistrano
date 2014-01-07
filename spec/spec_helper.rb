require 'rspec'
require 'rake'
require 'pry-debugger'
require 'fileutils'
require 'catch_and_release'
require 'catch_and_release/rspec'

require 'reek'
require 'reek/spec'

RSpec.configure do |c|
  c.include CatchAndRelease::RSpec
  c.include Reek::Spec
end

# for eating up stdout
output = StringIO.open('','w+')
$stdout = output

ROOT = Dir.pwd

require 'support/given'

#     Rake Helpers
# ----------------------------------------------------

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

def tracer msg
  STDOUT.puts "\n\n==========================\n\n#{msg}\n\n==========================\n"
end

#     Startup SimpleCov
# ----------------------------------------------------

require 'simplecov'
SimpleCov.start

require 'statistrano'