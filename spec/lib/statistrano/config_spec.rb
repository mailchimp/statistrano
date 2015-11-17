require 'spec_helper'

describe Statistrano::Config do

  describe "#initialize" do
    it "defaults options, tasks, & validators to a blank hash" do
      subject = described_class.new

      expect( subject.options ).to eq({})
      expect( subject.tasks ).to eq({})
      expect( subject.validators ).to eq({})
    end

    it "defines an accessor for each given option" do
      subject = described_class.new options: { foo: 'bar' }
      expect( subject.foo ).to eq 'bar'
    end

    it "uses given options, tasks, and validators, but clones so the originals don't get modified" do
      options    = { foo: 'bar' }
      tasks      = { foo: 'bar' }
      validators = { foo: lambda { |arg| arg } }

      subject = described_class.new options: options, tasks: tasks, validators: validators

      subject.foo              = 'baz'
      subject.tasks[:foo]      = 'baz'
      subject.validators[:foo] = lambda { |arg| 'baz' }

      expect( subject.foo ).to eq 'baz'
      expect( options ).to eq foo: 'bar'

      expect( subject.tasks ).to eq foo: 'baz'
      expect( tasks ).to eq foo: 'bar'

      expect( subject.validators[:foo].call('arg') ).to eq 'baz'
      expect( validators[:foo].call('arg') ).to eq 'arg'
    end
  end

end
