require 'spec_helper'

describe Statistrano::Deployment::Manifest do

  it "should not reek" do
    expect( Dir["lib/statistrano/deployment/manifest.rb"] ).not_to reek
  end

end