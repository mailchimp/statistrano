require 'spec_helper'

describe Statistrano::Deployment::Strategy::Base do

  it "is registered as :base" do
    expect( Statistrano::Deployment::Strategy.find(:base) ).to eq described_class
  end

  describe "#initialize" do
    it "sets name to given name" do
      subject = described_class.new "hello"
      expect( subject.name ).to eq "hello"
    end
  end

  describe "#deploy" do

    before :each do
      @remote   = instance_double("Statistrano::Remote").as_null_object
      @releaser = instance_double("Statistrano::Deployment::Releaser::Revisions").as_null_object
      allow( Statistrano::Remote ).to receive(:new)
                                  .and_return(@remote)
      allow( Statistrano::Deployment::Releaser::Single ).to receive(:new)
                                                        .and_return(@releaser)
      @subject = define_deployment "base", :base do
        remote_dir "/tmp"
        local_dir  "/tmp"
        hostname   "localhost"
        build_task { "empty block" }
      end
    end

    context "when check_git is set to true" do
      it "runs `safe_to_deploy? (and exits if false)" do
        subject = define_deployment "base", :base do
          check_git  true
          git_branch 'master'
        end

        expect( subject ).to receive(:safe_to_deploy?)
                         .and_return( false )

        expect{
          subject.deploy
        }.to raise_error SystemExit
      end
    end

    it "runs `invoke_build_task`" do
      expect( @subject ).to receive(:invoke_build_task)
      @subject.deploy
    end

    it "calls create_release for the releaser" do
      expect( @releaser ).to receive(:create_release)
                         .with( @remote )

      @subject.deploy
    end

    it "calls the post_deploy_task" do
      expect( @subject ).to receive(:invoke_post_deploy_task)
      @subject.deploy
    end
  end

end