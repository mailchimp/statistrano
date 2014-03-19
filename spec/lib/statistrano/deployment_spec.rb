require 'spec_helper'

describe Statistrano::Deployment do

  def store_types_cache
    @types_cache = described_class.instance_variable_get(:@_types)
  end

  def restore_types_cache
    described_class.instance_variable_set(:@_types, @types_cache)
  end

  def remove_types_cache
    if described_class.instance_variable_defined?(:@_types)
      described_class.send(:remove_instance_variable, :@_types)
    end
  end

  before :all do
    store_types_cache
  end

  after :all do
    restore_types_cache
  end

  before :each do
    class Foo; end
    class Woo; end
    remove_types_cache
  end

  describe "::types" do

    it "returns the @_types variable" do
      described_class.instance_variable_set(:@_types, 'foo')
      expect( described_class.types ).to eq 'foo'
    end

    it "defaults to a Hash if no types are set" do
      hash = {}
      expect( described_class.types ).to eq hash
    end

  end

  describe "::register_type" do

    it "adds the class to the types cache" do
      described_class.register_type(Foo,:foo)
      expect( described_class.types[:foo] ).to eq Foo
    end

    it "symbolizes provided names" do
      described_class.register_type(Woo,'woo')
      expect( described_class.types ).to have_key :woo
    end

  end

  describe "::find" do

    it "returns registered deployments" do
      described_class.register_type(Foo,:foo)
      expect( described_class.find(:foo) ).to eq Foo
    end

    it "raises an UndefinedDeployment error if no deployment defined" do
      expect {
        described_class.find(:missing)
      }.to raise_error Statistrano::Deployment::UndefinedDeployment
    end

  end

end

describe Statistrano::Deployment::Registerable do
  describe "::register_type" do
    it "calls register type on Deployment" do
      expect( Statistrano::Deployment ).to receive(:register_type)
                                       .with( Foo, :foo )

      class Foo
        extend Statistrano::Deployment::Registerable

        register_type :foo
      end
    end
  end
end