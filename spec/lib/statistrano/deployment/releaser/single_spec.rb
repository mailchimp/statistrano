require 'spec_helper'

describe Statistrano::Deployment::Releaser::Single do

  let(:default_remote_config_responses) do
    {
      remote_dir: '/var/www/proj',
      local_dir:  'build'
    }
  end

  describe "#initialize" do
    it "creates a release_name based on current time" do
      allow( Time ).to receive(:now).and_return(12345)
      subject = described_class.new
      expect( subject.release_name ).to eq "12345"
    end
  end

  describe "#create_release" do
    it "runs through the pipeline" do
      remote  = instance_double("Statistrano::Remote")
      subject = described_class.new

      expect(subject).to receive(:setup).with(remote)
      expect(subject).to receive(:rsync_to_remote).with(remote)

      subject.create_release remote, {}
    end
  end

  describe "#setup" do
    it "creates the remote_dir on the target" do
      config  = double("Statistrano::Config", default_remote_config_responses)
      remote  = instance_double("Statistrano::Remote", config: config )
      subject = described_class.new

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
      subject = described_class.new

      allow( Dir ).to receive(:pwd).and_return('/local')
      expect( remote ).to receive(:rsync_to_remote)
                      .with( '/local/build', '/var/www/proj' )
                      .and_return( HereOrThere::Response.new("","",true) )
      subject.rsync_to_remote remote
    end
  end

end
