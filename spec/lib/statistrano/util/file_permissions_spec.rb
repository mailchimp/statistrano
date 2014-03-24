require 'spec_helper'

describe Statistrano::Util::FilePermissions do

  describe "#initialize" do
    it "sets user, group, and others based on given perm integer" do
      subject = described_class.new 644

      expect( subject.user ).to eq   "6"
      expect( subject.group ).to eq  "4"
      expect( subject.others ).to eq "4"
    end
  end

  describe "#to_chmod" do
    it "returns an object with the correct user, group, and others" do
      subject = described_class.new( 644 ).to_chmod

      expect( subject.user ).to eq   "rw"
      expect( subject.group ).to eq  "r"
      expect( subject.others ).to eq "r"
    end
  end

end