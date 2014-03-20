require 'spec_helper'

describe "Statistrano::Deployment::Releases integration", :integration do

  describe "makes release deployments" do

    before :all do
      Given.fixture "base"

      RSpec::Mocks.with_temporary_scope do
        define_deployment "releases1", :releases do |c|
          c.build_task = 'remote:copy'
          c.remote = 'localhost'
          c.local_dir = 'build'
          c.remote_dir = File.join( Dir.pwd, 'deployment' )
        end

        allow( Time ).to receive(:now)
                     .and_return(1372020000)
        reenable_rake_tasks
        Rake::Task["releases1:deploy"].invoke

        allow( Time ).to receive(:now)
                     .and_return(1372030000)
        reenable_rake_tasks
        Rake::Task["releases1:deploy"].invoke
      end
    end

    after :all do
      Given.cleanup!
    end


    it "generates releases with the correct timestamp" do
      expect( release_folder_contents ).to match_array ["1372020000","1372030000"]
    end

    it "symlinks the pub_dir to the most recent release" do
      out = Statistrano::Shell.run_local("ls -l deployment").stdout
      expect( out ).to match /current -> #{Dir.pwd.gsub("/", "\/")}\/deployment\/releases\/1372030000/
    end

    it "returns a list of the currently deployed deployments" do
      output = catch_stdout {
        Rake::Task["releases1:list"].invoke
      }.split("\n")

      expect( output[0].match("current") ).to be_truthy
      expect( output[0].match("Sun Jun 23, 2013 at  7:26 pm") ).to be_truthy
      expect( output[1].match("Sun Jun 23, 2013 at  4:40 pm") ).to be_truthy
    end
  end

  describe "restricts to the release count and rolls back" do

    before :all do
      Given.fixture "base"

      RSpec::Mocks.with_temporary_scope do
        define_deployment "releases2", :releases do |c|
          c.build_task = 'remote:copy'
          c.remote = 'localhost'
          c.local_dir = 'build'
          c.remote_dir = File.join( Dir.pwd, 'deployment' )
          c.release_count = 2
        end

        allow( Time ).to receive(:now)
                     .and_return(1372020000)
        reenable_rake_tasks
        Rake::Task["releases2:deploy"].invoke

        allow( Time ).to receive(:now)
                     .and_return(1372030000)
        reenable_rake_tasks
        Rake::Task["releases2:deploy"].invoke

        allow( Time ).to receive(:now)
                     .and_return(1372040000)
        reenable_rake_tasks
        Rake::Task["releases2:deploy"].invoke
      end
    end

    after :all do
      Given.cleanup!
    end

    it "removes the oldest deployment" do
      expect( release_folder_contents ).to match_array ["1372030000","1372040000"]
    end

    it "rolls back to the previous release" do
      Rake::Task["releases2:rollback"].invoke
      resp = Statistrano::Shell.run_local "ls -l deployment"

      expect( resp.stdout.match("current -> #{Dir.pwd}/deployment/releases/1372030000") ).to be_truthy
      expect( release_folder_contents == ["1372030000"] ).to be_truthy
    end

    it "won't rollback if there is only one release" do
      expect {
        reenable_rake_tasks
        Rake::Task["releases2:rollback"].invoke
      }.to raise_error(SystemExit)
      expect( release_folder_contents ).to match_array ["1372030000"]
    end

  end

end