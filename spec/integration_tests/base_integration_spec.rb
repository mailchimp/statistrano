require 'spec_helper'

describe "Base deployment integration test" do

  after :each do
    cleanup_fixture
  end

  it "deploys the contents of source to the 'deploy' folder" do
    pick_fixture "base_site"
    define_deployment "base" do |c|
      c.build_task = 'remote:copy'
      c.remote = 'localhost'
      c.local_dir = 'build'
      c.remote_dir = File.join( Dir.pwd, 'deployment' )
    end
    Rake::Task["base:deploy"].invoke
    result_a, source = Statistrano::Shell.run("ls source")
    result_b, deployment = Statistrano::Shell.run("ls deployment")
    result_a.should be_true
    result_b.should be_true
    deployment.should == source
  end

  it "doesn't create a deployment on the remote & should return false if there is a build error" do
    pick_fixture "error_on_build"
    Statistrano::Shell.run("rake error:deploy").should be_false
    Dir.exists?("deployment").should be_false
  end

end