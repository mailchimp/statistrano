require 'spec_helper'

describe Statistrano::Deployment::Releases do

  describe "#new" do
    it "creates a deployment with a name" do
      deployment = Statistrano::Deployment::Releases.new("name")
      expect( deployment.name ).to eq "name"
    end

    it "respects the default configs" do
      deployment = Statistrano::Deployment::Releases.new("name")
      expect( deployment.config.release_count ).to eq 5
    end

    it "allows configs to be changed" do
      deployment = Statistrano::Deployment::Releases.new("name")
      deployment.config.release_count = 10
      expect( deployment.config.release_count ).to eq 10
    end
  end

  it "should not reek" do
    expect( Dir["lib/statistrano/deployment/releases.rb"] ).not_to reek
  end

end