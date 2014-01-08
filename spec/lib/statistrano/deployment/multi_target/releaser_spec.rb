require 'spec_helper'

describe Statistrano::Deployment::MultiTarget::Releaser do

  let(:default_arguments) do
    {
      remote_dir: '/var/www/proj',
      local_dir: 'build'
    }
  end

  describe "#initialize" do
    it "assigns options hash to configuration" do
      subject = described_class.new default_arguments.merge(release_count: 10)
      expect( subject.config.release_count ).to eq 10
    end

    it "uses config.options defaults if option not given" do
      subject = described_class.new default_arguments
      expect( subject.config.release_dir ).to eq "releases"
    end

    it "requires a remote_dir to be set" do
      args = default_arguments.dup
      args.delete(:remote_dir)
      expect{
        described_class.new args
      }.to raise_error ArgumentError, "a remote_dir is required"
    end

    it "requires a local_dir to be set" do
      args = default_arguments.dup
      args.delete(:local_dir)
      expect{
        described_class.new args
      }.to raise_error ArgumentError, "a local_dir is required"
    end

    it "generates release_name from current time" do
      time = Time.now
      allow( Time ).to receive(:now).and_return(time)
      subject = described_class.new default_arguments

      allow( Time ).to receive(:now).and_return(time + 1)
      expect( Time.now ).not_to eq time # ensure that the time + 1 works
      expect( subject.release_name ).to eq time.to_i.to_s
    end
  end

  describe "#setup_release_path" do
    it "creates the release_path on the target" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new default_arguments

      expect( target ).to receive(:create_remote_dir)
                      .with( File.join( '/var/www/proj/releases', subject.release_name ) )
      subject.setup_release_path target
    end
  end

  describe "#rsync_to_remote" do
    it "calls rsync_to_remote on the target with the local_dir & release_path" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new default_arguments

      allow( Dir ).to receive(:pwd).and_return('/local')
      expect( target ).to receive(:rsync_to_remote)
                      .with( '/local/build', File.join( '/var/www/proj/releases', subject.release_name ) )
      subject.rsync_to_remote target
    end
  end

  describe "#symlink_release" do
    it "runs symlink command on target" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new default_arguments
      release_path = File.join( '/var/www/proj/releases', subject.release_name )

      expect( target ).to receive(:run)
                      .with( "ln -nfs #{release_path} /var/www/proj/current" )
      subject.symlink_release target
    end
  end

end