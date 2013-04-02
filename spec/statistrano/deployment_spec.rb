require 'spec_helper'

describe Statistrano::Deployment::Base do

  describe '#new' do

    it "creates a deployment with a name" do
      deployment = Statistrano::Deployment::Base.new("name")
      deployment.name.should == "name"
    end

    it "creates a configuration if a block is given" do
      deployment = Statistrano::Deployment::Base.new("name") do |config|
        config.remote_dir = "hello"
        config.local_dir = "world"
        config.remote = "foo"
      end

      deployment.config.remote_dir.should == "hello"
      deployment.config.local_dir.should == "world"
      deployment.config.remote.should == "foo"
    end
  end

end