require 'spec_helper'

describe Statistrano::Deployment::MultiTarget::Manifest do

  describe "#initialize" do
    it "stores the provided remote_dir & target" do
      target     = :target
      remote_dir = :remote_dir
      subject = described_class.new( remote_dir, target )

      expect( subject.remote_dir ).to eq remote_dir
      expect( subject.target ).to eq target
    end
  end

  describe "#data" do
    it "returns serialized data from target" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new '/var/www/proj', target
      expect( target ).to receive(:run)
                      .with('cat /var/www/proj/manifest.json')
                      .and_return( HereOrThere::Response.new('[{"key":"val"}]','',true))

      expect( subject.data ).to match_array [{ key: 'val' }]
    end

    it "returns empty array if manifest file is missing" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new '/var/www/proj', target
      expect( target ).to receive(:run)
                      .with('cat /var/www/proj/manifest.json')
                      .and_return( HereOrThere::Response.new("","cat: /var/www/proj/manifest.json: No such file or directory\n",false))

      expect( subject.data ).to match_array []
    end

    it "logs error when manifest contains invalid JSON" do
      config  = double("Statistrano::Config", remote: 'web01')
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      subject = described_class.new '/var/www/proj', target
      expect( target ).to receive(:run)
                      .with('cat /var/www/proj/manifest.json')
                      .and_return( HereOrThere::Response.new("invalid","",true))
      expect_any_instance_of( Statistrano::Log ).to receive(:error)
      subject.data
    end

    it "returns @_data if set" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new '/var/www/proj', target

      subject.instance_variable_set(:@_data, 'data')
      expect( subject.data ).to eq 'data'
    end

    it "sets @_data with return" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new '/var/www/proj', target
      allow( target ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )

      data = subject.data
      expect( subject.instance_variable_get(:@_data) ).to eq data
    end
  end

  describe "#push" do
    it "adds data to the data array" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      allow( target ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      subject = described_class.new '/var/www/proj', target

      new_data = {foo: 'bar'}
      subject.push new_data
      expect( subject.data ).to include new_data
    end

    it "symbolizes keys in passed data" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      allow( target ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      subject = described_class.new '/var/www/proj', target

      new_data = {"foo" => 'bar'}
      subject.push new_data
      expect( subject.data ).to include foo: 'bar'
    end

    it "raises error if provided data cannot be converted to JSON" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      allow( target ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      subject = described_class.new '/var/www/proj', target

      data = double
      expect( data ).to receive(:respond_to?)
                    .with(:to_json).and_return(false)

      expect{
        subject.push data
      }.to raise_error ArgumentError, "data must be serializable as JSON"
    end
  end

  describe "#remove_if" do
    it "removes data that matches the condition" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      allow( target ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      subject = described_class.new '/var/www/proj', target

      subject.remove_if { |item| item.has_key?(:key) }
      expect( subject.data ).to match_array []
    end
    it "retains data that doesn't match condition" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      allow( target ).to receive(:run).and_return( HereOrThere::Response.new('[{"key":"val"}]','',true) )
      subject = described_class.new '/var/www/proj', target

      subject.remove_if { |item| !item.has_key?(:key) }
      expect( subject.data ).to match_array [{key:"val"}]
    end
  end

end