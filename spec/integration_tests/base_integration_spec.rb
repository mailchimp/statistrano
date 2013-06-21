require 'spec_helper'
require 'fileutils'

describe "deployment with Base" do

  after(:each) do
    # cleanup the deployment
    FileUtils.rm_rf File.join( Dir.getwd, "deployment" )
  end

  it "deploys the contents of source to the 'deploy' folder" do
    pick_fixture "base_site"
    Statistrano::Shell.run "rake local:deploy"
    result_a, source = Statistrano::Shell.run("ls source")
    result_b, deployment = Statistrano::Shell.run("ls deployment")
    result_a.should be_true
    result_b.should be_true
    deployment.should == source
  end

end