require 'spec_helper'

describe Statistrano::Deployment::Base do

  describe '#new' do

    it "creates a deployment with a name" do
      deployment = Statistrano::Deployment::Base.new("name")
      expect( deployment.name ).to eq "name"
    end

    it "configuration is configurable" do
      deployment = Statistrano::Deployment::Base.new("name")
      deployment.config.remote_dir = "hello"
      deployment.config.local_dir = "world"
      deployment.config.remote = "foo"

      expect( deployment.config.remote_dir ).to eq "hello"
      expect( deployment.config.local_dir ).to eq "world"
      expect( deployment.config.remote ).to eq "foo"
    end

  end

  it "should not reek" do
    expect( Dir["lib/statistrano/deployment/base.rb"] ).not_to reek
  end

end