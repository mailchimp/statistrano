require 'spec_helper'

describe "Statistrano::Deployment::Strategy::Releases#prune_releases integration", :integration do

  context "with multiple_targets target" do

    before :each do
      Given.fixture "releases-deployed"
      @subject = define_deployment "releases", :releases do
        build_task "remote:copy"
        local_dir  "build"
        hostname   "localhost"
        remote_dir File.join( Dir.pwd, "deployment" )

        release_count 1
        remotes [
          { remote_dir: File.join( Dir.pwd, "deployment", "target01" ) },
          { remote_dir: File.join( Dir.pwd, "deployment", "target02" ) },
          { remote_dir: File.join( Dir.pwd, "deployment", "target03" ) }
        ]
      end
    end

    after :each do
      Given.cleanup!
    end

    it "removes older releases beyond release count" do
      @subject.prune_releases
      expect( multi_release_folder_contents )
        .to match_array [ "target01/releases/1372040000",
                          "target02/releases/1372040000",
                          "target03/releases/1372040000" ]
    end

    it "removes stray/untracked releases" do
      Given.file "deployment/target01/releases/foo_bar/index.html", ''
      Given.file "deployment/target02/releases/foo_bar/index.html", ''
      Given.file "deployment/target03/releases/foo_bar/index.html", ''
      @subject.prune_releases
      expect( multi_release_folder_contents )
        .to match_array [ "target01/releases/1372040000",
                          "target02/releases/1372040000",
                          "target03/releases/1372040000" ]
    end

    it "won't remove the currently symlinked release" do
      Given.symlink "deployment/target01/releases/1372030000", "deployment/target01/current"
      Given.symlink "deployment/target02/releases/1372030000", "deployment/target02/current"
      Given.symlink "deployment/target03/releases/1372030000", "deployment/target03/current"

      @subject.prune_releases

      expect( multi_release_folder_contents )
        .to match_array [ "target01/releases/1372030000",
                          "target01/releases/1372040000",

                          "target02/releases/1372030000",
                          "target02/releases/1372040000",

                          "target03/releases/1372030000",
                          "target03/releases/1372040000" ]
    end

    it "won't remove the currently symlinked release even if untracked" do
      Given.file    "deployment/target01/releases/foo_bar/index.html", ''
      Given.file    "deployment/target02/releases/foo_bar/index.html", ''
      Given.file    "deployment/target03/releases/foo_bar/index.html", ''
      Given.symlink "deployment/target01/releases/foo_bar", "deployment/target01/current"
      Given.symlink "deployment/target02/releases/foo_bar", "deployment/target02/current"
      Given.symlink "deployment/target03/releases/foo_bar", "deployment/target03/current"

      @subject.prune_releases

      expect( multi_release_folder_contents )
        .to match_array [ "target01/releases/foo_bar",
                          "target01/releases/1372040000",

                          "target02/releases/foo_bar",
                          "target02/releases/1372040000",

                          "target03/releases/foo_bar",
                          "target03/releases/1372040000" ]
    end
  end
end
