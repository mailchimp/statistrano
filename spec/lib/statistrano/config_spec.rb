require 'spec_helper'

describe Statistrano::Config do

  describe "#initialize" do
    it "defaults options & tasks to a blank hash" do
      subject = described_class.new

      expect( subject.options ).to eq({})
      expect( subject.tasks ).to eq({})
    end

    it "defines an accessor for each given option" do
      subject = described_class.new foo: 'bar'
      expect( subject.foo ).to eq 'bar'
    end

    it "uses given options & tasks, but clones so the originals don't get modified" do
      options = { foo: 'bar' }
      tasks   = { foo: 'bar' }
      subject = described_class.new options, tasks

      subject.foo         = 'baz'
      subject.tasks[:foo] = 'baz'

      expect( subject.foo ).to eq 'baz'
      expect( options ).to eq foo: 'bar'

      expect( subject.tasks ).to eq foo: 'baz'
      expect( tasks ).to eq foo: 'bar'
    end
  end

  describe "#task" do
  end

  describe "#task_namespace" do
  end

  describe "#remote_action" do
  end

end
