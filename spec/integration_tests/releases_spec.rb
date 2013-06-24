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
$stderr = output

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

  let :deployment do
    define_deployment "local", :releases do |c|
      c.build_task = 'remote:copy'
      c.remote = 'localhost'
      c.local_dir = 'build'
      c.remote_dir = File.join( Dir.pwd, 'deployment' )
    end
  end

  after(:each) do
    cleanup_fixture
  end

  describe ":deploy" do
    it "generates releases with the correct timestamp" do
      time = Time.at(1372020000)
      Timecop.freeze(time)
      Rake::Task["local:deploy"].invoke

      time = Time.at(1372030000)
      Timecop.travel(time)
      Rake::Task["local:deploy"].reenable
      Rake::Task["remote:copy"].reenable
      Rake::Task["local:deploy"].invoke

      Dir[ "deployment/releases/**" ].map { |d| d.gsub("deployment/releases/", '' ) }.should == ["1372020000","1372030000"]
    end
  end

  describe ":list" do
  end

  describe ":prune" do
  end

  describe ":rollback" do
  end

end