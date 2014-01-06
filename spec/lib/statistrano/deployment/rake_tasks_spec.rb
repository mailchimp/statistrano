require 'spec_helper'

describe Statistrano::Deployment::RakeTasks do

  it "generates rake tasks for a deployment" do
    deployment = Statistrano::Deployment::Base.new("name")
    expect( Rake::Task.tasks ).to include Rake::Task["name:deploy"]
  end

end