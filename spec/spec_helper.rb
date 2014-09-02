require 'rspec'
require 'rake'
require 'rainbow'
require 'fileutils'
require 'catch_and_release'
require 'catch_and_release/rspec'

RSpec.configure do |c|

  c.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles        = true
  end

  c.include CatchAndRelease::RSpec
end

if ENV['DEBUG']
  require 'pry'
end

# for eating up stdout & stderr
unless ENV['VERBOSE']
  stdout  = StringIO.open('','w+')
  $stdout = stdout

  stderr  = StringIO.open('','w+')
  $stderr = stderr
end

unless ENV['RAINBOW']
  Rainbow.enabled = false
end

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

def multi_release_folder_contents
  Dir[ "deployment/**/**" ].keep_if do |path|
    path.match /releases\/(.+)/
  end.keep_if do |path|
    File.directory?(path)
  end.map do |dir|
    dir.sub("deployment/",'')
  end
end

def tracer msg
  STDOUT.puts "\n\n==========================\n\n#{msg}\n\n==========================\n"
end

#     Startup SimpleCov
# ----------------------------------------------------

require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end

require 'statistrano'
