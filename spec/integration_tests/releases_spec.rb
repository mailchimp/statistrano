require 'spec_helper'

include ::Rake::DSL
namespace :remote do
  task :copy do
    `cp -r source/ build/ 2> /dev/null`
  end
end

# for eating up stdout
output = StringIO.open('','w')
$stdout = output

describe "Releases deployment integration test" do

  before(:each) do
    pick_fixture "releases_site"
    define_deployment "local", :releases do |c|
      c.build_task = 'remote:copy'
      c.remote = 'localhost'
      c.local_dir = 'build'
      c.remote_dir = File.join( Dir.pwd, 'deployment' )
    end
  end

  after(:each) do
    # cleanup_fixture
  end

  describe ":deploy" do
    it "does stuff" do
      Rake::Task["local:deploy"].invoke
    end
  end

  describe ":list" do
  end

  describe ":prune" do
  end

  describe ":rollback" do
  end

end