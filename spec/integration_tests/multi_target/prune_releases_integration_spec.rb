require 'spec_helper'

describe "Statistrano::Deployment::MultiTarget#prune_releases integration", :integration do

  context "with multiple_targets target" do

    before :each do
      Given.fixture "multi_target-deployed"
      @subject = define_deployment "multi_target", :multi_target do
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
  end
end