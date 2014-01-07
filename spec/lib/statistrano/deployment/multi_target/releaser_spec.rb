require 'spec_helper'

describe Statistrano::Deployment::MultiTarget::Releaser do

  describe "#initialize" do
    it "assigns options hash to configuration" do
      subject = described_class.new release_count: 10
      expect( subject.config.release_count ).to eq 10
    end

    it "uses config.options defaults if option not given" do
      subject = described_class.new release_count: 10
      expect( subject.config.release_dir ).to eq "releases"
    end
  end

end