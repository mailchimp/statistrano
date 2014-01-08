require 'spec_helper'

describe Statistrano::Deployment::MultiTarget::Releaser do

  describe "#initialize" do
    it "assigns options hash to configuration" do
      subject = described_class.new remote_dir: '/var/www/proj', release_count: 10
      expect( subject.config.release_count ).to eq 10
    end

    it "uses config.options defaults if option not given" do
      subject = described_class.new remote_dir: '/var/www/proj', release_count: 10
      expect( subject.config.release_dir ).to eq "releases"
    end

    it "requires a remote_dir to be set" do
      expect{
        described_class.new release_count: 10
      }.to raise_error ArgumentError, "a remote_dir is required"
    end

    it "generates release_name from current time" do
      time = Time.now
      allow( Time ).to receive(:now).and_return(time)
      subject = described_class.new remote_dir: '/var/www/proj'

      allow( Time ).to receive(:now).and_return(time + 1)
      expect( Time.now ).not_to eq time # ensure that the time + 1 works
      expect( subject.release_name ).to eq time.to_i.to_s
    end
  end

  describe "#setup_release_path" do
    it "creates the release_path on the target" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new remote_dir: '/var/www/proj'

      expect( target ).to receive(:create_remote_dir)
                      .with( File.join( '/var/www/proj/releases', subject.release_name ) )
      subject.setup_release_path target
    end
  end

end