require 'spec_helper'

describe Statistrano::Deployment::Manifest do

  it "should not reek" do
    Dir["lib/statistrano/deployment/manifest.rb"].should_not reek
  end


end