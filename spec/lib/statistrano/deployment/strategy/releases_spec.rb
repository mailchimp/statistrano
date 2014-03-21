require 'spec_helper'

describe Statistrano::Deployment::Strategy::Releases do

  describe "#new" do
    it "creates a deployment with a name" do
      deployment = described_class.new("name")
      expect( deployment.name ).to eq "name"
    end

    it "respects the default configs" do
      deployment = described_class.new("name")
      expect( deployment.config.release_count ).to eq 5
    end

    it "allows configs to be changed" do
      deployment = described_class.new("name")
      deployment.config.release_count = 10
      expect( deployment.config.release_count ).to eq 10
    end
  end

end