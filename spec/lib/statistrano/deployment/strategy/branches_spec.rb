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
  end

  it "validates public_dir not empty or '/'" do
    deployment = described_class.new("name")

    expect{
      deployment.config.public_dir ""
    }.to raise_error Statistrano::Config::ValidationError

    expect{
      deployment.config.public_dir "/"
    }.to raise_error Statistrano::Config::ValidationError
  end

end
