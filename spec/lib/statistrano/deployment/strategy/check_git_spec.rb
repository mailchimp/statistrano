require 'spec_helper'

describe Statistrano::Deployment::Strategy::CheckGit do

  before :each do
    class Subject
      include Statistrano::Deployment::Strategy::CheckGit

      def config
        Struct.new(:check_git,:git_branch).new(true,'master')
      end
    end

    allow( Asgit ).to receive(:working_tree_clean?).and_return(true)
    allow( Asgit ).to receive(:current_branch).and_return('master')
    allow( Asgit ).to receive(:remote_up_to_date?).and_return(true)
  end

  let(:subject) { Subject.new }

  describe "#safe_to_deploy?" do
    it "is false if the working_tree is dirty" do
      allow( Asgit ).to receive(:working_tree_clean?).and_return(false)
      expect( subject.safe_to_deploy? ).to be_falsy
    end
    it "is false if the current_branch does not match set branch" do
      allow( Asgit ).to receive(:current_branch).and_return('not_master')
      expect( subject.safe_to_deploy? ).to be_falsy
    end
    it "is false if out of sync with remote" do
      allow( Asgit ).to receive(:remote_up_to_date?).and_return(false)
      expect( subject.safe_to_deploy? ).to be_falsy
    end
    it "is true if working_tree is clean, on correct branch, and in sync with remote" do
      expect( subject.safe_to_deploy? ).to be_truthy
    end
  end

end