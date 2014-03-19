require 'spec_helper'

describe "Statistrano::Deployment::Base integration", :integration do

  after :each do
    Given.cleanup!
  end

  it "deploys the contents of source to the 'deploy' folder" do
    Given.fixture "base"
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
    Given.fixture "error_on_build"
    expect( Statistrano::Shell.run_local("rake error:deploy") ).not_to be_success #confirming the error

    expect( Dir.exists?("deployment") ).to be_falsy
  end

end