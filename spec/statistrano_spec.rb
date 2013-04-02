require 'spec_helper'

describe Statistrano do

  describe "#define_deployment" do
    it "creates a new deployment with a name" do
      deployment = define_deployment("hello")
      deployment.name.should == "hello"
    end

    it "allows the deployment to be configured" do
      deployment = define_deployment "hello" do |config|
        config.remote_dir = "/var/www/example.com"
      end

      deployment.config.remote_dir.should == "/var/www/example.com"
    end
  end

end