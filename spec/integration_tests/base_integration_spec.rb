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
    result_a = Statistrano::Shell.run_local("ls source")
    result_b = Statistrano::Shell.run_local("ls deployment")
    expect( result_a ).to be_success
    expect( result_b ).to be_success
    expect( result_a.stdout ).to eq result_b.stdout
  end

  it "doesn't create a deployment on the remote & should return false if there is a build error" do
    pick_fixture "error_on_build"
    Statistrano::Shell.run("rake error:deploy").should be_false
    Dir.exists?("deployment").should be_false
  end

end