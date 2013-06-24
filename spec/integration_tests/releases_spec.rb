require 'spec_helper'

include ::Rake::DSL
namespace :remote do
  task :copy do
    puts "build task running"
    `cp -r source/ build/ 2> /dev/null`
  end
end

# for eating up stdout
output = StringIO.open('','w+')
$stdout = output

describe "Releases deployment integration test" do

  def tracer
    puts "============================"
  end

  before(:all) do
    pick_fixture "releases_site"
    define_deployment "local", :releases do |c|
      c.build_task = 'remote:copy'
      c.remote = 'localhost'
      c.local_dir = 'build'
      c.remote_dir = File.join( Dir.pwd, 'deployment' )
    end
  end

  before(:each) do
    pick_fixture "releases_site"
    time = Time.at(1372020000)
    Timecop.freeze(time)
    Rake::Task["local:deploy"].reenable
    Rake::Task["remote:copy"].reenable
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
    Timecop.return
    cleanup_fixture
  end

  describe ":deploy" do
    it "generates releases with the correct timestamp" do
      Rake::Task["local:deploy"].invoke

      Rake::Task["local:deploy"].reenable
      Rake::Task["remote:copy"].reenable
      Timecop.travel(10000)
      Rake::Task["local:deploy"].invoke

      Dir[ "deployment/releases/**" ].map { |d| d.gsub("deployment/releases/", '' ) }.should == ["1372020000","1372030000"]
    end

    it "symlinks the pub_dir to the most recent release" do
      Rake::Task["local:deploy"].invoke

      status, stdout = Statistrano::Shell.run("ls -l deployment")
      stdout.should =~ /current -> #{Dir.pwd.gsub("/", "\/")}\/deployment\/releases\/1372020000/
    end
  end

  describe ":list" do
    it "lists the previous releases" do
      Rake::Task["local:deploy"].invoke

      Rake::Task["local:deploy"].reenable
      Rake::Task["remote:copy"].reenable
      Timecop.travel(10000)
      Rake::Task["local:deploy"].invoke

      $stdout.rewind
      Rake::Task["local:list"].invoke
      $stdout.rewind
      $stdout.readlines[1..2].should == ["\e[0;30;49m-> \e[0m   \e[0;34;49mcurrent\e[0m  Sun Jun 23, 2013 at  7:26 pm\n", "\e[0;30;49m-> \e[0m          \e[0;34;49m\e[0m  Sun Jun 23, 2013 at  4:40 pm\n"]
    end
  end

  describe ":prune" do
    it "doesn't remove releases under the max count" do
    end
    it "removes old releases outside the max count" do
    end
  end

  describe ":rollback" do
    it "symlinks the previous release and removes the most current" do
    end
  end

end