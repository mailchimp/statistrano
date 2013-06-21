require 'spec_helper'

describe "deployment with Base" do

  before(:each) do
    pick_fixture "base_site"
  end

  after(:each) do
    cleanup_fixture
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