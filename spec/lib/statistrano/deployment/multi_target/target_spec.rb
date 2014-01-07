require 'spec_helper'

describe Statistrano::Deployment::MultiTarget::Target do

  let(:default_options) do
    {
      remote:           'web01',
      user:             nil,
      password:         nil,
      keys:             nil,
      forward_agent:    nil
    }
  end

  def create_ssh_double
    ssh_double = instance_double("HereOrThere::Remote::SSH")
    allow_any_instance_of( Statistrano::Config ).to receive(:ssh_session).and_return(ssh_double)
    return ssh_double
  end

  describe "#initialize" do
    it "assigns options hash to configuration" do
      subject = described_class.new default_options
      expect( subject.config.options ).to eq default_options
    end
    it "uses config.options defaults if option not given" do
      subject = described_class.new
      expect( subject.config.remote ).to be_nil
    end
  end

  describe "#run" do
    it "passes command to ssh_session#run" do
      ssh_double = create_ssh_double
      subject = described_class.new default_options

      expect( ssh_double ).to receive(:run).with('ls')
      subject.run 'ls'
    end
  end

  describe "#done" do
    it "passes close_session command to ssh_session" do
      ssh_double = create_ssh_double
      subject = described_class.new default_options

      expect( ssh_double ).to receive(:close_session)
      subject.done
    end
  end

  describe "#create_remote_dir" do
    it "runs mkdir command on remote" do
      ssh_double = create_ssh_double
      subject = described_class.new

      expect( ssh_double ).to receive(:run).with("mkdir -p /var/www/proj")
      subject.create_remote_dir "/var/www/proj"
    end

    it "requires an absolute path" do
      ssh_double = create_ssh_double
      subject = described_class.new

      expect {
        subject.create_remote_dir "var/www/proj"
      }.to raise_error ArgumentError, "path must be absolute"
    end
  end

end