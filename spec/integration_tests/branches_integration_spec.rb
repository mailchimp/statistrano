require 'spec_helper'

include ::Rake::DSL
namespace :remote do
  task :copy do
    `cp -r source/ build/ 2> /dev/null`
  end
end

# for eating up stdout
output = StringIO.open('','w+')
$stdout = output

# patch in the branch of our choosing
module Statistrano
  module Git
    class << self
      def branch= branch
        @branch = branch
      end
      def current_branch
        @branch || "current_branch"
      end
    end
  end
end

describe "creates and manages deployments" do

  before :all do

    pick_fixture "branches_site"
    tracer Time.now

    Statistrano::Git.branch = "first_branch"
    define_deployment "local1", :branches do |c|
      c.build_task = 'remote:copy'
      c.remote = 'localhost'
      c.local_dir = 'build'
      c.remote_dir = File.join( Dir.pwd, 'deployment' )
    end
    Rake::Task["local1:deploy"].invoke

    Rake::Task["remote:copy"].reenable
    Statistrano::Git.branch = "second_branch"
    define_deployment "local2", :branches do |c|
      c.build_task = 'remote:copy'
      c.remote = 'localhost'
      c.local_dir = 'build'
      c.remote_dir = File.join( Dir.pwd, 'deployment' )
    end
    Rake::Task["local2:deploy"].invoke
  end

  after :all do
    cleanup_fixture
  end

  it "generates a release at the specified branches" do
    ["first_branch", "index", "second_branch"].each do |dir|
      Dir[ "deployment/**" ].map { |d| d.gsub("deployment/", '' ) }.include?(dir).should be_true
    end
  end

end