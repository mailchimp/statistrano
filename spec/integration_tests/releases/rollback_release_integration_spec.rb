require 'spec_helper'

describe "Statistrano::Deployment::Strategy::Releases#rollback_release integration", :integration do

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

    it "reverts to the previous release" do
      # just to verify that 137204000 is the current release
      # on all targets
      ["target01","target02","target03"].each do |target|
        ls_before = HereOrThere::Local.new.run("ls -la deployment/#{target}")
        expect( ls_before.stdout ).to match /current ->(.+)tmp\/deployment\/#{target}\/releases\/1372040000/
      end

      @subject.rollback_release

      ["target01","target02","target03"].each do |target|
        ls_after = HereOrThere::Local.new.run("ls -la deployment/#{target}")
        expect( ls_after.stdout ).to match /current ->(.+)tmp\/deployment\/#{target}\/releases\/1372030000/
      end
    end

  end

end