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
      ssh_double = instance_double("HereOrThere::Remote::SSH")
      allow_any_instance_of( Statistrano::Config ).to receive(:ssh_session).and_return(ssh_double)
      subject = described_class.new default_options

      expect( ssh_double ).to receive(:run).with('ls')
      subject.run 'ls'
    end
  end

  describe "#done" do
    it "passes close_session command to ssh_session" do
      ssh_double = instance_double("HereOrThere::Remote::SSH")
      allow_any_instance_of( Statistrano::Config ).to receive(:ssh_session).and_return(ssh_double)
      subject = described_class.new default_options

      expect( ssh_double ).to receive(:close_session)
      subject.done
    end
  end

end