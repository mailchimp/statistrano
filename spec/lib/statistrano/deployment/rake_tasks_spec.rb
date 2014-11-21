require 'spec_helper'

describe Statistrano::Deployment::RakeTasks do

  describe "::register" do
    before :each do
      class RakeTasksSubject
        extend Statistrano::Config::Configurable
        include Statistrano::Deployment::Strategy::InvokeTasks

        attr_reader :name

        task :foo, :bar, "baz"

        def initialize name
          @name = name
        end

        def bar
          "baz"
        end
      end
    end

    after :each do
      Rake::Task.clear
    end

    it "registers tasks using deployment's name as namespace" do
      described_class.register RakeTasksSubject.new "woo"
      expect( Rake::Task.tasks.map(&:to_s) ).to include 'woo:foo'
    end

    it "calls the tasks matching method on the deployment" do
      subject = RakeTasksSubject.new "woo"
      described_class.register subject

      expect( subject ).to receive(:bar)

      Rake::Task['woo:foo'].invoke
    end

  end

  describe "::register_user_task" do
    it "adds the task in the correct namespace" do
      deployment_double = instance_double("Statistrano::Deployment::Strategy::Base", name: 'name')
      Statistrano::Deployment::RakeTasks.register_user_task deployment_double, 'puma', 'start' do
        puts "puma:start"
      end
      expect( Rake::Task.tasks.map(&:to_s) ).to include 'name:puma:start'
    end
    it "yields the deployment if arity is given" do
      deployment_double = instance_double("Statistrano::Deployment::Strategy::Base", name: 'name')
      Statistrano::Deployment::RakeTasks.register_user_task deployment_double, 'puma', 'start' do |dep|
        dep.remotes
      end
      expect( deployment_double ).to receive(:remotes)
      Rake::Task['name:puma:start'].invoke
    end
  end

end
