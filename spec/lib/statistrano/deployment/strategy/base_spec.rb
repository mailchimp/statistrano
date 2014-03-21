require 'spec_helper'

describe Statistrano::Deployment::Strategy::Base do

  describe '#new' do

    it "creates a deployment with a name" do
      deployment = described_class.new("name")
      expect( deployment.name ).to eq "name"
    end

    it "configuration is configurable" do
      deployment = described_class.new("name")
      deployment.config.remote_dir = "hello"
      deployment.config.local_dir = "world"
      deployment.config.hostname = "foo"

      expect( deployment.config.remote_dir ).to eq "hello"
      expect( deployment.config.local_dir ).to eq "world"
      expect( deployment.config.hostname ).to eq "foo"
    end

  end

end