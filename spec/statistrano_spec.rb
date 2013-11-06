require 'spec_helper'

describe Statistrano do

  describe "#define_deployment" do
    it "creates a new deployment with a name" do
      deployment = define_deployment("hello")
      deployment.name.should == "hello"
    end

    it "creates a new deployment with the specified type" do
      default  = define_deployment("base")
      releases = define_deployment("releases", :releases)
      branches = define_deployment("branches", :branches)

      default.class.should  == Statistrano::Deployment::Base
      releases.class.should == Statistrano::Deployment::Releases
      branches.class.should == Statistrano::Deployment::Branches
    end

    it "raises and ArgumentError if a deployment type isn't defined" do
      expect{ define_deployment("foo", :foo) }.to raise_error NameError
    end

    it "allows the deployment to be configured" do
      deployment = define_deployment "hello" do |config|
        config.remote_dir = "/var/www/example.com"
      end

      releases = define_deployment "releases", :releases do |config|
        config.build_task = "build:something"
      end

      branch = define_deployment "branch", :branches do |config|
        config.base_domain = "foo.com"
      end

      deployment.config.remote_dir.should == "/var/www/example.com"
      branch.config.base_domain.should == "foo.com"
      releases.config.build_task.should == "build:something"
    end

    it "has a 'sugar' syntax for configuration" do
      deployment = define_deployment "hello" do
        remote_dir "/var/www/sugarandspice.com"
      end

      deployment.config.remote_dir.should == "/var/www/sugarandspice.com"
    end
  end

end