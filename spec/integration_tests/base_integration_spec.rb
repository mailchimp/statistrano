require 'spec_helper'

describe "Statistrano::Deployment::Base integration", :integration do

  after :each do
    reenable_rake_tasks
    Given.cleanup!
  end

  context "with a single remote" do
    it "deploys the contents of source to the 'deploy' folder" do
      Given.fixture "base"
      base = define_deployment "base" do |c|
        c.build_task = 'remote:copy'
        c.hostname   = 'localhost'
        c.local_dir  = 'build'
        c.remote_dir = File.join( Dir.pwd, 'deployment' )
      end

      base.deploy
      result_a = Statistrano::Shell.run_local("ls source")
      result_b = Statistrano::Shell.run_local("ls deployment")

      expect( result_a ).to be_success
      expect( result_b ).to be_success
      expect( result_a.stdout ).to eq result_b.stdout
    end

    it "doesn't create a deployment on the remote & should return false if there is a build error" do
      Given.fixture "error_on_build"
      expect( Statistrano::Shell.run_local("rake error:deploy") ).not_to be_success #confirming the error

      expect( Dir.exists?("deployment") ).to be_falsy
    end
  end

  context "with multiple remotes" do
    it "deploys the contents of source to each remote" do
      Given.fixture "base"
      base = define_deployment "base" do
        build_task "remote:copy"
        hostname   "localhost"
        local_dir  "build"
        remote_dir File.join( Dir.pwd, 'deployment' )

        remotes [
          { remote_dir: File.join( Dir.pwd, "deployment", "target01" ) },
          { remote_dir: File.join( Dir.pwd, "deployment", "target02" ) }
        ]
      end

      base.deploy

      expect( deployment_folder_contents ).to match_array [ "target01", "target02" ]
    end
  end

  context "with specific file permissions" do
    it "deploys with those permissions" do
      Given.fixture "base"
      base = define_deployment "base" do
        build_task "remote:copy"
        hostname   "localhost"
        local_dir  "build"
        remote_dir File.join( Dir.pwd, 'deployment' )

        # these are really bad perms on purpose
        dir_permissions 777
        file_permissions 666
      end

      base.deploy

      deployment_dir_perms  = sprintf( "%o", File.stat("deployment").mode ).chars.to_a.last(3).join
      deployment_file_perms = sprintf( "%o", File.stat("deployment/index.html").mode ).chars.to_a.last(3).join

      expect( deployment_dir_perms ).to eq "777"
      expect( deployment_file_perms ).to eq "666"
    end
  end

end
