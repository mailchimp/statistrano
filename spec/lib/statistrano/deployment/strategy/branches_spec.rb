require 'spec_helper'

describe Statistrano::Deployment::Strategy::Branches do

  describe "#new" do
    it "creates a deployment with a name" do
      deployment = described_class.new("name")
      expect( deployment.name ).to eq "name"
    end

    it "respects the default configs" do
      allow( Asgit ).to receive(:current_branch).and_return('first_branch')
      deployment = described_class.new("name")

      expect( deployment.config.public_dir ).to eq "first_branch"
    end

    it "prevents the public_dir from being an empty string" do
    end
  end

end
