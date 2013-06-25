require 'spec_helper'

extend PatchTime
include ::Rake::DSL
namespace :remote do
  task :copy do
    `cp -r source/ build/ 2> /dev/null`
  end
end

# for eating up stdout
output = StringIO.open('','w+')
$stdout = output

describe "Releases deployment integration test" do

  describe "makes release deployments" do

    before :all do
      pick_fixture "releases_site"
      define_deployment "local", :releases do |c|
        c.build_task = 'remote:copy'
        c.remote = 'localhost'
        c.local_dir = 'build'
        c.remote_dir = File.join( Dir.pwd, 'deployment' )
      end
      set_time(1372020000)
      Rake::Task["local:deploy"].invoke

      Rake::Task["local:deploy"].reenable
      Rake::Task["remote:copy"].reenable
      set_time(1372030000)
      Rake::Task["local:deploy"].invoke
    end

    after :all do
      cleanup_fixture
    end


    it "generates releases with the correct timestamp" do
      Dir[ "deployment/releases/**" ].map { |d| d.gsub("deployment/releases/", '' ) }.should == ["1372020000","1372030000"]
    end

    it "symlinks the pub_dir to the most recent release" do
      status, stdout = Statistrano::Shell.run("ls -l deployment")
      stdout.should =~ /current -> #{Dir.pwd.gsub("/", "\/")}\/deployment\/releases\/1372030000/
    end

    it "returns a list of the currently deployed deployments" do
      $stdout.rewind
      Rake::Task["local:list"].invoke
      $stdout.rewind
      $stdout.readlines[1..2].should == ["\e[0;30;49m-> \e[0m   \e[0;34;49mcurrent\e[0m  Sun Jun 23, 2013 at  7:26 pm\n", "\e[0;30;49m-> \e[0m          \e[0;34;49m\e[0m  Sun Jun 23, 2013 at  4:40 pm\n"]
    end
  end

  describe "restricts to the release count and rolls back" do

    before :all do
      pick_fixture "releases_site"
      define_deployment "local2", :releases do |c|
        c.build_task = 'remote:copy'
        c.remote = 'localhost'
        c.local_dir = 'build'
        c.remote_dir = File.join( Dir.pwd, 'deployment' )
        c.release_count = 2
      end
      set_time(1372020000)
      Rake::Task["remote:copy"].reenable
      Rake::Task["local2:deploy"].invoke

      Rake::Task["local2:deploy"].reenable
      Rake::Task["remote:copy"].reenable
      set_time(1372030000)
      Rake::Task["local2:deploy"].invoke

      Rake::Task["local2:deploy"].reenable
      Rake::Task["remote:copy"].reenable
      set_time(1372040000)
      Rake::Task["local2:deploy"].invoke
    end

    after :all do
      cleanup_fixture
    end

    it "removes the oldest deployment" do
      Dir[ "deployment/releases/**" ].map { |d| d.gsub("deployment/releases/", '' ) }.should == ["1372030000","1372040000"]
    end

    it "rolls back to the previous release" do
      Rake::Task["local2:rollback"].invoke
      status, stdout = Statistrano::Shell.run("ls -l deployment")
      stdout.should =~ /current -> #{Dir.pwd.gsub("/", "\/")}\/deployment\/releases\/1372030000/
      Dir[ "deployment/releases/**" ].map { |d| d.gsub("deployment/releases/", '' ) }.should == ["1372030000"]
    end

  end

end