require 'spec_helper'

describe Statistrano::Git do

  # Patch the output of the Shell.run method
  # so that we can test against expected results
  before(:all) do
    module Statistrano::Shell
      class << self
        def run command, &block
          yield SHELL_OUT
        end
      end
    end
  end

  describe "patching of shell works" do
    it "returns what we patch with" do
      SHELL_OUT = "expected"
      Statistrano::Shell.run "ls" do |output|
        output.should == "expected"
      end
    end
  end

  describe "#working_tree_clean?" do
    it "is true when nothing to commit" do
      SHELL_OUT = "# On branch master\n" +
                  "nothing to commit, working directory clean"
      Statistrano::Git.working_tree_clean?.should be_true
    end
    it "is false when tree isn't clean" do
      SHELL_OUT = "# On branch master\n" +
                  "# Untracked files:\n" +
                  "#   (use \"git add <file>...\" to include in what will be committed)\n" +
                  "#\n" +
                  "# foo\n" +
                  "nothing added to commit but untracked files present (use \"git add\" to track)\n"
      Statistrano::Git.working_tree_clean?.should be_false
    end
  end

  describe "#current_branch" do
    it "returns master when on master" do
      SHELL_OUT = "refs/heads/master"
      Statistrano::Git.current_branch.should == "master"
    end
  end

  describe "#current_commit" do
    it "returns current commit" do
      SHELL_OUT = "12345"
      Statistrano::Git.current_commit.should == "12345"
    end
  end

  describe "#remote_up_to_date?" do
    it "returns true if remote is current" do
      SHELL_OUT = "Everything up-to-date"
      Statistrano::Git.remote_up_to_date?.should be_true
    end
    it "returns false if remote is out of sync" do
      SHELL_OUT = "To git@github.com:mailchimp/statistrano.git\n" +
                  "fbe7c67..3cf2934  HEAD -> master"
      Statistrano::Git.remote_up_to_date?.should be_false
    end
  end

end