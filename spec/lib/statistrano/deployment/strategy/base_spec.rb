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

      it "will exit if build changes checked in files" do
        subject = define_deployment "base", :base do
          check_git true
          git_branch 'master'

          build_task do
            # no-op
          end
        end

        expect( subject ).to receive(:safe_to_deploy?)
                         .and_return( true, false ) # simulate git being clear
                                                    # before the build task, but not
                                                    # after

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
                         .with( @remote, {} )

      @subject.deploy
    end

    it "calls the post_deploy_task" do
      expect( @subject ).to receive(:invoke_post_deploy_task)
      @subject.deploy
    end

    context "when log_file_path is set" do

      before :each do
        @subject = define_deployment "base", :base do
          remote_dir "/tmp"
          local_dir  "/tmp"
          hostname   "localhost"
          build_task do
            { build_task: 'data' }
          end
          post_deploy_task do
            { post_deploy_task: 'data' }
          end

          log_file_path '/log/path'
          log_file_entry do |dep, rel, build_data, post_deploy_data|
            {
              log: 'entry',
            }.merge( build_data ).merge( post_deploy_data )
          end
        end
      end

      it "should create a Remote::File for the log & append log_file_entry to it" do
        log_file_double = instance_double("Statistrano::Remote::File")
        expect( Statistrano::Remote::File ).to receive(:new)
                              .with('/log/path', @remote)
                              .and_return( log_file_double )
        expect( log_file_double ).to receive(:append_content!)
                                 .with('{"log":"entry","build_task":"data","post_deploy_task":"data"}')

        @subject.deploy
      end

      it "if given relative path, makes it relative to release_dir" do
        @subject.config.log_file_path = "log"
        log_file_double = instance_double("Statistrano::Remote::File")
        expect( Statistrano::Remote::File ).to receive(:new)
                              .with('/tmp/log', @remote)
                              .and_return( log_file_double )
        allow( log_file_double ).to receive(:append_content!)

        @subject.deploy
      end
    end

    context "when log_file_path isn't set" do
      it "doesn't create a log file" do
        expect( Statistrano::Remote::File ).not_to receive(:new)
        @subject.deploy
      end
    end
  end

  describe "#persited_releaser" do
    it "returns same object each time it's called" do
      subject = define_deployment "base", :base do
        remote_dir "/tmp"
        local_dir  "/tmp"
        hostname   "localhost"
        build_task { "empty block" }
      end

      expect( subject.persisted_releaser ).to eq subject.persisted_releaser
    end
  end

  describe "#flush_persisted_releaser!" do
    it "removes the persisted_releaser" do
      subject = define_deployment "base", :base do
        remote_dir "/tmp"
        local_dir  "/tmp"
        hostname   "localhost"
        build_task { "empty block" }
      end

      first_releaser = subject.persisted_releaser
      subject.flush_persisted_releaser!

      expect( subject.persisted_releaser ).not_to eq first_releaser
    end
  end

end
