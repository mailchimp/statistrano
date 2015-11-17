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
      validators = { foo: { validator: lambda { |arg| arg } } }

      subject = described_class.new options: options, tasks: tasks, validators: validators

      subject.foo              = 'baz'
      subject.tasks[:foo]      = 'baz'
      subject.validators[:foo] = { validator: lambda { |arg| 'baz' } }

      expect( subject.foo ).to eq 'baz'
      expect( options ).to eq foo: 'bar'

      expect( subject.tasks ).to eq foo: 'baz'
      expect( tasks ).to eq foo: 'bar'

      expect( subject.validators[:foo][:validator].call('arg') ).to eq 'baz'
      expect( validators[:foo][:validator].call('arg') ).to eq 'arg'
    end
  end

  describe "#accessor set" do
    context "when a validator is set" do
      let(:subject) do
        subject = described_class.new options: { string: '', integer: '' },
                                      validators: {
                                        string: { validator: lambda { |i| !i.to_s.empty? } },
                                        integer: { validator: lambda { |i| i.is_a?(Integer) } }
                                      }

        subject.validators[:integer][:message] = "not an integer"

        subject
      end

      it "is peachy with a valid value" do
        expect{
          subject.validate_string 'a string'
        }.not_to raise_error
      end

      it "raises when validating invalid value" do
        expect{
          subject.validate_string ''
        }.to raise_error Statistrano::Config::ValidationError
      end

      it "raises while validating with given message" do
        expect{
          subject.validate_integer 'foobar'
        }.to raise_error Statistrano::Config::ValidationError, 'not an integer'
      end

      it "raises when set to invalid value" do
        expect{
          subject.integer 'foo'
        }.to raise_error Statistrano::Config::ValidationError
      end


    end
  end

end
