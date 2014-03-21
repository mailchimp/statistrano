require 'spec_helper'

describe Statistrano::Deployment::Strategy do

  def store_registered_cache
    @registered_cache = described_class.instance_variable_get(:@_registered)
  end

  def restore_registered_cache
    described_class.instance_variable_set(:@_registered, @registered_cache)
  end

  def remove_registered_cache
    if described_class.instance_variable_defined?(:@_registered)
      described_class.send(:remove_instance_variable, :@_registered)
    end
  end

  before :all do
    store_registered_cache
  end

  after :all do
    restore_registered_cache
  end

  before :each do
    class Foo; end
    class Woo; end
    remove_registered_cache
  end

  describe "::registered" do

    it "returns the @_registered variable" do
      described_class.instance_variable_set(:@_registered, 'foo')
      expect( described_class.registered ).to eq 'foo'
    end

    it "defaults to a Hash if no registered are set" do
      hash = {}
      expect( described_class.registered ).to eq hash
    end

  end

  describe "::register" do

    it "adds the class to the strategy cache" do
      described_class.register(Foo,:foo)
      expect( described_class.registered[:foo] ).to eq Foo
    end

    it "symbolizes provided names" do
      described_class.register(Woo,'woo')
      expect( described_class.registered ).to have_key :woo
    end

  end

  describe "::find" do

    it "returns registered strategy" do
      described_class.register(Foo,:foo)
      expect( described_class.find(:foo) ).to eq Foo
    end

    it "raises an UndefinedStrategy error if no strategy defined" do
      expect {
        described_class.find(:missing)
      }.to raise_error Statistrano::Deployment::Strategy::UndefinedStrategy
    end

  end

end