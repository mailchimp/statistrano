require 'spec_helper'

describe Statistrano::Deployment::Branches do

  describe "#new" do
    it "creates a deployment with a name" do
      deployment = Statistrano::Deployment::Branches.new("name")
      deployment.name.should == "name"
    end

    it "respects the default configs" do
      Asgit.stub( current_branch: 'first_branch' )
      deployment = Statistrano::Deployment::Branches.new("name")

      deployment.config.public_dir.should == "first_branch"
      deployment.config.post_deploy_task.should == "name:generate_index"
    end
  end

  it "should not reek" do
    Dir["lib/statistrano/deployment/branches.rb"].should_not reek
  end

end