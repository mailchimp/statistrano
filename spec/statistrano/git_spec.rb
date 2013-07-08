require 'spec_helper'

describe Statistrano::Git do

  describe "#working_tree_clean?" do
    it "is true when nothing to commit" do
      fake_stdout "# On branch master\n" +
                  "nothing to commit, working directory clean" do
        Statistrano::Git.working_tree_clean?.should be_true
      end
    end
    it "is false when tree isn't clean" do
      fake_stdout "# On branch master\n" +
                  "# Untracked files:\n" +
                  "#   (use \"git add <file>...\" to include in what will be committed)\n" +
                  "#\n" +
                  "# foo\n" +
                  "nothing added to commit but untracked files present (use \"git add\" to track)\n" do
        Statistrano::Git.working_tree_clean?.should be_false
      end
    end
  end

  describe "#current_branch" do
    it "returns master when on master" do
      fake_stdout "refs/heads/master" do
        Statistrano::Git.current_branch.should == "master"
      end
    end
  end

  describe "#current_commit" do
    it "returns current commit" do
      fake_stdout "12345" do
        Statistrano::Git.current_commit.should == "12345"
      end
    end
  end

  describe "#remote_up_to_date?" do
    it "returns true if remote is current" do
      fake_stderr "Everything up-to-date" do
        Statistrano::Git.remote_up_to_date?.should be_true
      end
    end
    it "returns false if remote is out of sync" do
      fake_stderr "To git@github.com:mailchimp/statistrano.git\n" +
                  "fbe7c67..3cf2934  HEAD -> master" do
        Statistrano::Git.remote_up_to_date?.should be_false
      end
    end
  end

end