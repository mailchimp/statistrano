require 'spec_helper'

describe "Statistrano::Deployment::Branches integration", :integration do

  context "with a single remote" do
    before :all do
      Given.fixture "base"

      RSpec::Mocks.with_temporary_scope do
        @deployment = define_deployment "branches", :branches do |c|
          c.build_task  = 'remote:copy'
          c.hostname    = 'localhost'
          c.local_dir   = 'build'
          c.remote_dir  = File.join( Dir.pwd, 'deployment' )
          c.base_domain = "example.com"
        end

        allow( Asgit ).to receive(:current_branch)
                      .and_return('first_branch')
        allow( Time ).to receive(:now)
                     .and_return(1372020000)
        @deployment.deploy

        allow( Asgit ).to receive(:current_branch)
                      .and_return('second_branch')
        allow( Time ).to receive(:now)
                     .and_return(1372030000)
        @deployment.deploy
      end
    end

    after :each do
      reenable_rake_tasks
    end

    after :all do
      Given.cleanup!
    end

    it "generates a release at the specified branches" do
      ["first_branch", "index", "second_branch"].each do |dir|
        expect( deployment_folder_contents ).to include dir
      end
    end

    it "lists the deployed branches" do
      output = catch_stdout {
        @deployment.list_releases
      }
      expect( output ).to include "first_branch"
      expect( output ).to include "second_branch"
    end

    it "generates an index page with the correct order of branches" do
      index_html = IO.read("deployment/index/index.html")
      expect( index_html ).to include <<-eof
        <li>
          <a href="http://second_branch.example.com">second_branch</a>
          <small>updated: Sunday Jun 23, 2013 at  7:26 pm</small>
        </li>
      
        <li>
          <a href="http://first_branch.example.com">first_branch</a>
          <small>updated: Sunday Jun 23, 2013 at  4:40 pm</small>
        </li>
eof
    end

    it "removes the selected branch to prune" do
      release_stdin 1 do
        @deployment.prune_releases
        expect( Dir[ "deployment/**" ] ).not_to include "deployment/first_branch"

        manifest_json = JSON.parse(IO.read("deployment/manifest.json"))
        expect( manifest_json.map { |d| d["name"] } ).not_to include "first_branch"
      end
    end
  end

  context "with multiple remotes" do
    before :all do
      Given.fixture "base"

      RSpec::Mocks.with_temporary_scope do
        @deployment = define_deployment "branches", :branches do
          build_task  'remote:copy'
          hostname    'localhost'
          local_dir   'build'
          base_domain "example.com"
          remote_dir  File.join( Dir.pwd, 'deployment' )

          remotes [
            { remote_dir: File.join( Dir.pwd, 'deployment', 'remote01' ) },
            { remote_dir: File.join( Dir.pwd, 'deployment', 'remote02' ) }
          ]
        end

        allow( Asgit ).to receive(:current_branch)
                      .and_return('first_branch')
        allow( Time ).to receive(:now)
                     .and_return(1372020000)
        @deployment.deploy

        allow( Asgit ).to receive(:current_branch)
                      .and_return('second_branch')
        allow( Time ).to receive(:now)
                     .and_return(1372030000)
        @deployment.deploy
      end
    end

    after :each do
      reenable_rake_tasks
    end

    after :all do
      Given.cleanup!
    end

    def deployment_dir_contents
      Dir[ "deployment/**/*" ].map do |e|
        e.sub /^deployment\/?/, ''
      end
    end

    it "creates a release on each remote" do
      expect( deployment_dir_contents ).to match_array [
        "remote01",
        "remote01/index",
        "remote01/index/index.html",
        "remote01/first_branch",
        "remote01/first_branch/index.html",
        "remote01/second_branch",
        "remote01/second_branch/index.html",
        "remote01/manifest.json",

        "remote02",
        "remote02/index",
        "remote02/index/index.html",
        "remote02/first_branch",
        "remote02/first_branch/index.html",
        "remote02/second_branch",
        "remote02/second_branch/index.html",
        "remote02/manifest.json"
      ]
    end

    it "lists the deployed branches" do
      @deployment.list_releases
      output = catch_stdout {
        @deployment.list_releases
      }
      expect( output ).to include "first_branch"
      expect( output ).to include "second_branch"
    end

    it "generates an index page with the correct order of branches" do
      expected_html = <<-eof
        <li>
          <a href="http://second_branch.example.com">second_branch</a>
          <small>updated: Sunday Jun 23, 2013 at  7:26 pm</small>
        </li>
      
        <li>
          <a href="http://first_branch.example.com">first_branch</a>
          <small>updated: Sunday Jun 23, 2013 at  4:40 pm</small>
        </li>
eof

      expect( IO.read("deployment/remote01/index/index.html") ).to include expected_html
      expect( IO.read("deployment/remote02/index/index.html") ).to include expected_html
    end

    it "removes the selected branch to prune" do
      # verify deployments are there to begin with
      expect( deployment_dir_contents ).to include "remote01/first_branch"
      expect( deployment_dir_contents ).to include "remote02/first_branch"

      release_stdin 1 do
        @deployment.prune_releases
      end

      expect( deployment_dir_contents ).not_to include "remote01/first_branch"
      expect( deployment_dir_contents ).not_to include "remote02/first_branch"

      # verify the one we didn't remove is still there
      expect( deployment_dir_contents ).to include "remote01/second_branch"
      expect( deployment_dir_contents ).to include "remote02/second_branch"
    end
  end

end
