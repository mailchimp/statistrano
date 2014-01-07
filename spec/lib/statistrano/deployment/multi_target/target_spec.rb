require 'spec_helper'

describe Statistrano::Deployment::MultiTarget::Target do

  let(:default_options) do
    {
      remote_dir:       'remote',
      local_dir:        'local',
      remote:           'web01',
      user:             nil,
      password:         nil,
      keys:             nil,
      forward_agent:    nil,
      release_count:    5,
      release_dir:      "releases",
      public_dir:       "current"
    }
  end

  describe "#initialize" do
    it "assigns options hash to configuration" do
      subject = described_class.new default_options
      expect( subject.config.options ).to eq default_options
    end
    it "uses config.options defaults if option not given" do
      subject = described_class.new
      expect( subject.config.release_count ).to eq 5
      expect( subject.config.release_dir ).to eq "releases"
      expect( subject.config.public_dir ).to eq "current"
    end
  end

end