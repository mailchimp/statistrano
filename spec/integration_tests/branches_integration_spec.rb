require 'spec_helper'

describe "creates and manages deployments" do

  before :all do
    pick_fixture "branches_site"

    Statistrano::Git.set_branch "first_branch"
    deployment = define_deployment "branches1", :branches do |c|
      c.build_task = 'remote:copy'
      c.remote = 'localhost'
      c.local_dir = 'build'
      c.remote_dir = File.join( Dir.pwd, 'deployment' )
    end

    reenable_rake_tasks
    Rake::Task["branches1:deploy"].invoke

    Statistrano::Git.set_branch "second_branch"
    deployment.config.public_dir = Statistrano::Git.current_branch

    reenable_rake_tasks
    Rake::Task["branches1:deploy"].invoke
  end

  after :all do
    cleanup_fixture
    Statistrano::Git.unset_branch
  end

  it "generates a release at the specified branches" do
    ["first_branch", "index", "second_branch"].each do |dir|
      deployment_folder_contents.include?(dir).should be_true
    end
  end

  it "lists the deployed branches" do
    $stdout.rewind
    Rake::Task["branches1:list"].invoke
    $stdout.rewind
    lines = Array($stdout.readlines[1..2])
    lines[0].include?("first_branch").should be_true
    lines[1].include?("second_branch").should be_true
  end

  it "removes the selected branch to prune" do
    fake_stdin(1) do
      Rake::Task["branches1:prune"].invoke
      Dir[ "deployment/**" ].map { |d| d.gsub( "deployment/", "" ) }.include?("first_branch").should be_false
    end
  end

end