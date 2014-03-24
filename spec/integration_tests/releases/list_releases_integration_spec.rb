require 'spec_helper'

describe "Statistrano::Deployment::Strategy::Releases#list_releases integration", :integration do

  context "with multiple_targets target" do

    before :each do
      Given.fixture "releases-deployed"
      @subject = define_deployment "releases", :releases do
        build_task "remote:copy"
        local_dir  "build"
        hostname   "localhost"
        remote_dir File.join( Dir.pwd, "deployment" )

        release_count 2
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

    it "lists currently deployed releases" do
      output = catch_stdout do
        @subject.list_releases
      end

      expect( output ).to match /->(.+?)localhost(.+?)\[\"1372040000\", \"1372030000\"\]/
    end

  end

end