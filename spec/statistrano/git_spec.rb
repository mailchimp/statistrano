require 'spec_helper'

describe Statistrano::Git do

  describe "#working_tree_clean?" do
    it "is true when nothing to commit" do
      HereOrThere::Response.any_instance.stub(
        stdout: "# On branch master\n" +
        "nothing to commit, working directory clean"
      )

      expect( Statistrano::Git.working_tree_clean? ).to be_true
    end

    it "is false when tree isn't clean" do
      HereOrThere::Response.any_instance.stub(
        stdout: "# On branch master\n" +
                "# Untracked files:\n" +
                "#   (use \"git add <file>...\" to include in what will be committed)\n" +
                "#\n" +
                "# foo\n" +
                "nothing added to commit but untracked files present (use \"git add\" to track)\n"
      )

      expect( Statistrano::Git.working_tree_clean? ).to be_false
    end
  end

  describe "#current_branch" do
    it "returns master when on master" do
      HereOrThere::Response.any_instance.stub(
        stdout: "refs/heads/master"
      )

      expect( Statistrano::Git.current_branch ).to eq "master"
    end
  end

  describe "#current_commit" do
    it "returns current commit" do
      HereOrThere::Response.any_instance.stub(
        stdout: "12345"
      )
      expect( Statistrano::Git.current_commit ).to eq "12345"
    end
  end

  describe "#remote_up_to_date?" do
    it "returns true if remote is current" do
      HereOrThere::Response.any_instance.stub(
        stderr: "Everything up-to-date"
      )
      expect( Statistrano::Git.remote_up_to_date? ).to be_true
    end
    it "returns false if remote is out of sync" do
      HereOrThere::Response.any_instance.stub(
        stderr: "To git@github.com:mailchimp/statistrano.git\n" +
                "fbe7c67..3cf2934  HEAD -> master"
      )
      expect( Statistrano::Git.remote_up_to_date? ).to be_false
    end
  end

end