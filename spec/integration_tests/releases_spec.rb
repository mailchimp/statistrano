require 'spec_helper'

describe "Releases deployment integration test" do

  before(:each) do
    pick_fixture "releases_site"
  end

  after(:each) do
    cleanup_fixture
  end

  describe ":deploy" do
  end

  describe ":list" do
  end

  describe ":prune" do
  end

  describe ":rollback" do
  end

end