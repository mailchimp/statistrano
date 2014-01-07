require 'spec_helper'

describe Statistrano::Deployment::MultiTarget do

  it "is registered as :multi_target" do
    expect( Statistrano::Deployment.find(:multi_target) ).to eq described_class
  end

  describe "#targets" do

    let(:default_options) do
      {
        remote_dir:       nil,
        local_dir:        nil,
        remote:           nil,
        user:             nil,
        password:         nil,
        keys:             nil,
        forward_agent:    nil,
        build_task:       nil,
        check_git:        nil,
        git_branch:       nil,
        repo_url:         nil,
        post_deploy_task: nil,
        release_count:    5,
        release_dir:      "releases",
        public_dir:       "current"
      }
    end

    it "returns targets cache if set" do
      subject = described_class.new 'multi'
      subject.instance_variable_set(:@_targets, 'targets')

      expect( subject.targets ).to eq 'targets'
    end

    it "sets target cache with results" do
      subject = described_class.new 'multi'
      targets = subject.targets

      expect( targets ).not_to be_nil
      expect( subject.instance_variable_get(:@_targets) ).to eq targets
    end

    it "initializes a MultiTarget::Target with each target" do
      deployment = define_deployment "multi", :multi_target do
        targets [
          { remote: 'web01' },
          { remote: 'web02' }
        ]
      end

      expect( Statistrano::Deployment::MultiTarget::Target ).to receive(:new).exactly(2).times
      deployment.targets
    end

    it "merges target data with global data" do
      deployment = define_deployment "multi", :multi_target do
        remote_dir "remote_dir"
        targets [
          { remote: 'web01', remote_dir: 'web01_remote_dir' }
        ]
      end

      expect( Statistrano::Deployment::MultiTarget::Target ).to receive(:new)
        .with(default_options.merge({remote: 'web01', remote_dir: 'web01_remote_dir'}))
      deployment.targets
    end
  end

end