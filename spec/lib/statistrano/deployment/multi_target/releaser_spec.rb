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

    it "generates release_name from current time" do
      time = Time.now
      allow( Time ).to receive(:now).and_return(time)
      subject = described_class.new

      allow( Time ).to receive(:now).and_return(time + 1)
      expect( Time.now ).not_to eq time # ensure that the time + 1 works
      expect( subject.release_name ).to eq time.to_i.to_s
    end
  end

end