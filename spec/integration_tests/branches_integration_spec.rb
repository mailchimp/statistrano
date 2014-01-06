require 'spec_helper'

describe "creates and manages deployments", :integration do

  before :all do
    pick_fixture "branches_site"

    Asgit.stub( current_branch: 'first_branch' )
    deployment = define_deployment "branches1", :branches do |c|
      c.build_task = 'remote:copy'
      c.remote = 'localhost'
      c.local_dir = 'build'
      c.remote_dir = File.join( Dir.pwd, 'deployment' )
      c.base_domain = "example.com"
    end

    reenable_rake_tasks
    Time.stub( now: 1372020000 )
    Rake::Task["branches1:deploy"].invoke

    Asgit.stub( current_branch: 'second_branch' )
    deployment.config.public_dir = Asgit.current_branch

    reenable_rake_tasks
    Time.stub( now: 1372030000 )
    Rake::Task["branches1:deploy"].invoke
  end

  after :all do
    cleanup_fixture
  end

  it "generates a release at the specified branches" do
    ["first_branch", "index", "second_branch"].each do |dir|
      expect( deployment_folder_contents ).to include dir
    end
  end

  it "lists the deployed branches" do
    output = Capture.stdout {
      Rake::Task["branches1:list"].invoke
    }
    expect( output ).to include "first_branch"
    expect( output ).to include "second_branch"
  end

  it "generates an index page with the correct order of branches" do
    index_html = IO.read("deployment/index/index.html")
    expect( index_html ).to match /<li><a href="http:\/\/second_branch\.example\.com">second_branch<\/a><small>updated: Sunday Jun 23, 2013 at  7:26 pm<\/small><\/li><li><a href="http:\/\/first_branch\.example\.com">first_branch<\/a><small>updated: Sunday Jun 23, 2013 at  4:40 pm<\/small><\/li>/
  end

  it "removes the selected branch to prune" do
    fake_stdin(1) do
      Rake::Task["branches1:prune"].invoke
      expect( Dir[ "deployment/**" ] ).not_to include "deployment/first_branch"
    end
  end

end