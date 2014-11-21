require 'spec_helper'

describe Statistrano::Deployment::RakeTasks do

  describe "::register" do

    context "config tasks" do
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

    context "user_tasks" do

      after :each do
        Rake::Task.clear
      end

      it "adds the task in the correct namespace" do
        config            = Statistrano::Config.new
        deployment_double = instance_double("Statistrano::Deployment::Strategy::Base", name: 'name', config: config)
        config.user_tasks.push name: 'start',
                               namespaces: ['puma'],
                               block: lambda { }

        described_class.register deployment_double

        expect( Rake::Task.tasks.map(&:to_s) ).to include 'name:puma:start'
      end

      it "registers the task at top level if no namespaces" do
        config            = Statistrano::Config.new
        deployment_double = instance_double("Statistrano::Deployment::Strategy::Base", name: 'name', config: config)
        config.user_tasks.push name: 'start',
                               namespaces: [],
                               block: lambda { }

        described_class.register deployment_double

        expect( Rake::Task.tasks.map(&:to_s) ).to include 'name:start'
      end

      it "yields the deployment if arity is given" do
        config            = Statistrano::Config.new
        deployment_double = instance_double("Statistrano::Deployment::Strategy::Base", name: 'name', config: config)
        config.user_tasks.push name: 'start',
                               namespaces: ['puma'],
                               block: lambda { |dep| dep.remotes }
        described_class.register deployment_double

        expect( deployment_double ).to receive(:remotes)

        Rake::Task['name:puma:start'].invoke
      end

    end

  end

end
