require 'spec_helper'

describe Statistrano::Deployment::Base do

  describe '#new' do

    it "creates a deployment with a name" do
      deployment = Statistrano::Deployment::Base.new("name")
      deployment.name.should == "name"
    end

    it "configuration is configurable" do
      deployment = Statistrano::Deployment::Base.new("name")
      deployment.config.remote_dir = "hello"
      deployment.config.local_dir = "world"
      deployment.config.remote = "foo"

      deployment.config.remote_dir.should == "hello"
      deployment.config.local_dir.should == "world"
      deployment.config.remote.should == "foo"
    end

  end

end