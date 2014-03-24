require 'spec_helper'

describe Statistrano::Config::Configurable do

  class Subject
    extend ::Statistrano::Config::Configurable

    option :foo, "bar"
    option :wu
    option :proc, -> { "hello" }

    options :one, :two
  end

  let(:subject) { Subject.new }

  describe "#option" do

    it "sets the given default value" do
      expect( subject.config.foo ).to eq("bar")
    end

    it "defaults to setting nil" do
      expect( subject.config.wu ).to be_nil
    end

  end


  describe "#options" do
    it "creates an accessor for each given option" do
      names = [:one,:two]

      names.each do |meth|
        expect( subject.config.respond_to? meth ).to be_truthy
      end
    end

    it "defaults those values to nil" do
      names = [:one,:two]

      names.each do |meth|
        expect( subject.config.public_send meth ).to be_nil
      end
    end
  end

  describe "option accessor" do
    let(:config) { subject.config }

    it "returns the value if given no arguments" do
      expect( config.foo ).to eq("bar")
    end

    it "sets the value if given one argument" do
      config.foo "baz"
      expect( config.foo ).to eq("baz")
    end

    it "sets the value if given an #=" do
      config.foo = "badazz"
      expect( config.foo ).to eq("badazz")
    end

    it "sets the value to a block if given one" do
      config.foo do
        "badazz"
      end
      expect( config.foo.call ).to eq "badazz"
    end

    it "calls a block if `:call` is passed" do
      config.foo :call do
        "badazz"
      end
      expect( config.foo ).to eq "badazz"
    end

    it "raises and ArgumentError if given more than 1 argument" do
      expect{ config.foo "bar", "baz" }.to raise_error ArgumentError
    end

  end


end