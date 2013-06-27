require 'spec_helper'

describe Statistrano::Deployment::Branches do

  after :all do
    Statistrano::Git.unset_branch
  end

  describe "#new" do
    it "creates a deployment with a name" do
      deployment = Statistrano::Deployment::Branches.new("name")
      deployment.name.should == "name"
    end

    it "respects the default configs" do
      Statistrano::Git.set_branch "first_branch"
      deployment = Statistrano::Deployment::Branches.new("name")
      deployment.config.public_dir.should == "first_branch"
      deployment.config.post_deploy_task.should == "name:generate_index"
    end
  end

end