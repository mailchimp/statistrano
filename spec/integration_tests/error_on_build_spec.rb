require 'spec_helper'

describe "deployment with error on build" do

  before(:each) do
    pick_fixture "error_on_build"
  end

  after(:each) do
    cleanup_fixture
  end

  it "shouldn't create a deployment on the remote & should return false" do
    pick_fixture "error_on_build"
    Statistrano::Shell.run("rake local:deploy").should be_false
    Dir.exists?("deployment").should be_false
  end

end