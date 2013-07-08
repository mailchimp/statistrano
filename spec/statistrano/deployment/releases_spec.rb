require 'spec_helper'

describe Statistrano::Deployment::Releases do

  describe "#new" do
    it "creates a deployment with a name" do
      deployment = Statistrano::Deployment::Releases.new("name")
      deployment.name.should == "name"
    end

    it "respects the default configs" do
      deployment = Statistrano::Deployment::Releases.new("name")
      deployment.config.release_count.should == 5
    end

    it "allows configs to be changed" do
      deployment = Statistrano::Deployment::Releases.new("name")
      deployment.config.release_count = 10
      deployment.config.release_count.should == 10
    end
  end

  it "should not reek" do
    Dir["lib/statistrano/deployment/releases.rb"].should_not reek
  end

end