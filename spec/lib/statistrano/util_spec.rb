require 'spec_helper'

describe Statistrano::Util do

  describe "::symbolize_hash_keys" do
    it "symbolizes keys of hash" do
      expect(
        Statistrano::Util.symbolize_hash_keys( { 'foo' => 'bar' })
      ).to eq foo: 'bar'
    end
    it "symbolizes keys of nested hashes" do
      expect(
        Statistrano::Util.symbolize_hash_keys( { 'foo' => { 'bar' => 'baz' }})
      ).to eq foo: { bar: 'baz' }
    end
    it "symbolizes keys of hashes nested in arrays" do
      expect(
        Statistrano::Util.symbolize_hash_keys( { 'foo' => [{'bar'=>'baz'},{'wu'=>'tang'}]})
      ).to eq foo: [{bar:'baz'},{wu:'tang'}]
    end
  end

end