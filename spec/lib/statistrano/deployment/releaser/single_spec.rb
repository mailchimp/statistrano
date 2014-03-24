require 'spec_helper'

describe Statistrano::Deployment::Releaser::Single do

  let(:default_arguments) do
    {
      remote_dir: '/var/www/proj',
      local_dir:  'build'
    }
  end

  let(:default_remote_config_responses) do
    {
      remote_dir: nil,
      local_dir:  nil
    }
  end

  describe "#initialize" do
    it "assigns options hash to configuration" do
      subject = described_class.new default_arguments.merge(remote_dir: '/foo')
      expect( subject.config.remote_dir ).to eq '/foo'
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
  end

  describe "#create_release" do
    it "runs through the pipeline" do
      remote  = instance_double("Statistrano::Remote")
      subject = described_class.new default_arguments

      expect(subject).to receive(:setup).with(remote)
      expect(subject).to receive(:rsync_to_remote).with(remote)

      subject.create_release remote
    end
  end

  describe "#setup" do
    it "creates the remote_dir on the target" do
      config  = double("Statistrano::Config", default_remote_config_responses)
      remote  = instance_double("Statistrano::Remote", config: config )
      subject = described_class.new default_arguments

      expect( remote ).to receive(:run)
                      .with("mkdir -p /var/www/proj")
                      .and_return( HereOrThere::Response.new("","",true) )
      subject.setup remote
    end
  end

  describe "#rsync_to_remote" do
    it "calls rsync_to_remote on the remote with the local_dir & remote_dir" do
      config  = double("Statistrano::Config", default_remote_config_responses )
      remote  = instance_double("Statistrano::Remote", config: config )
      subject = described_class.new default_arguments

      allow( Dir ).to receive(:pwd).and_return('/local')
      expect( remote ).to receive(:rsync_to_remote)
                      .with( '/local/build', '/var/www/proj' )
                      .and_return( HereOrThere::Response.new("","",true) )
      subject.rsync_to_remote remote
    end
  end

end