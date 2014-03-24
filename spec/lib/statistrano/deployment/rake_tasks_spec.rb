require 'spec_helper'

describe Statistrano::Deployment::RakeTasks do

  describe "::register" do
    before :each do
      class Subject
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
      described_class.register Subject.new "woo"
      expect( Rake::Task.tasks.map(&:to_s) ).to include 'woo:foo'
    end

    it "calls the tasks matching method on the deployment" do
      subject = Subject.new "woo"
      described_class.register subject

      expect( subject ).to receive(:bar)

      Rake::Task['woo:foo'].invoke
    end

  end

end
