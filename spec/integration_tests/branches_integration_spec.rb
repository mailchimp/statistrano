require 'spec_helper'

describe "creates and manages deployments" do

  before :all do
    pick_fixture "branches_site"

    Statistrano::Git.set_branch "first_branch"
    define_deployment "branches1", :branches do |c|
      c.build_task = 'remote:copy'
      c.remote = 'localhost'
      c.local_dir = 'build'
      c.remote_dir = File.join( Dir.pwd, 'deployment' )
    end

    reenable_rake_tasks
    Rake::Task["branches1:deploy"].invoke

    Statistrano::Git.set_branch "second_branch"
    define_deployment "branches2", :branches do |c|
      c.build_task = 'remote:copy'
      c.remote = 'localhost'
      c.local_dir = 'build'
      c.remote_dir = File.join( Dir.pwd, 'deployment' )
    end

    reenable_rake_tasks
    Rake::Task["branches2:deploy"].invoke
  end

  after :all do
    cleanup_fixture
    Statistrano::Git.unset_branch
  end

  it "generates a release at the specified branches" do
    ["first_branch", "index", "second_branch"].each do |dir|
      Dir[ "deployment/**" ].map { |d| d.gsub("deployment/", '' ) }.include?(dir).should be_true
    end
  end

end