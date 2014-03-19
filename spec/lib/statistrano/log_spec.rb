require 'spec_helper'

describe Statistrano::Log do

  def clean_logger_cache
    if described_class.instance_variable_get(:@_logger)
      described_class.send(:remove_instance_variable, :@_logger)
    end
  end

  before :each do
    clean_logger_cache
  end

  after :each do
    clean_logger_cache
  end

  describe "::set_logger" do
    it "sets the logger" do
      Statistrano::Log.set_logger 'foo'
      expect( Statistrano::Log.instance_variable_get(:@_logger) ).to eq 'foo'
    end
  end

  describe "::logger_instance" do
    it "returns the cached logger" do
      Statistrano::Log.instance_variable_set(:@_logger, 'foo')
      expect( Statistrano::Log.logger_instance ).to eq 'foo'
    end
    it "initializes a new DefaultLogger if no logger is set" do
      expect( Statistrano::Log::DefaultLogger ).to receive(:new)
      Statistrano::Log.logger_instance
    end
  end
end
