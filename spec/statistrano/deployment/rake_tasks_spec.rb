require 'spec_helper'

describe Statistrano::Deployment::RakeTasks do

  it "generates rake tasks for a deployment" do
    deployment = Statistrano::Deployment::Base.new("name")
    Rake::Task.tasks.include?(Rake::Task["name:deploy"]).should be_true
  end

end