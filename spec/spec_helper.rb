require 'simplecov'
SimpleCov.start

require 'rspec'
require 'pry-debugger'
require 'statistrano'
require 'fileutils'

require 'reek'
require 'reek/spec'
RSpec.configure do |c|
  c.include(Reek::Spec)
end

# for eating up stdout
output = StringIO.open('','w+')
$stdout = output

ROOT = Dir.pwd

# support
require 'support/capture'

describe "support" do

  describe Capture do
    describe "#stdout" do
      it "returns a string representation fo what is sent to stdout inside the given block" do
        out = Capture.stdout { $stdout.puts "hello"; $stdout.puts "world" }
        expect( out ).to eq "hello\nworld\n"
      end
    end

    describe "#stderr" do
      it "returns a string representation fo what is sent to stderr inside the given block" do
        out = Capture.stderr { $stderr.puts "hello"; $stderr.puts "world" }
        expect( out ).to eq "hello\nworld\n"
      end
    end
  end

end


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


#     Patches STDIN for a block
# ----------------------------------------------------

def fake_stdin(*args)
  $stdin = StringIO.new
  $stdin.puts(args.shift) until args.empty?
  $stdin.rewind
  yield
ensure
  $stdin = STDIN
end