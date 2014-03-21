require 'spec_helper'

describe Statistrano::Deployment::Strategy::MultiTarget do

  it "is registered as :multi_target" do
    expect( Statistrano::Deployment::Strategy.find(:multi_target) ).to eq described_class
  end

  describe "#remotes" do

    let(:default_options) do
      {
        remote_dir:       nil,
        local_dir:        nil,
        hostname:         nil,
        user:             nil,
        password:         nil,
        keys:             nil,
        forward_agent:    nil,
        build_task:       nil,
        check_git:        nil,
        git_branch:       nil,
        repo_url:         nil,
        post_deploy_task: nil,
        release_count:    5,
        release_dir:      "releases",
        public_dir:       "current"
      }
    end

    it "returns remotes cache if set" do
      subject = described_class.new 'multi'
      subject.instance_variable_set(:@_remotes, 'remotes')

      expect( subject.remotes ).to eq 'remotes'
    end

    it "sets remote cache with results" do
      subject = described_class.new 'multi'
      remotes = subject.remotes

      expect( remotes ).not_to be_nil
      expect( subject.instance_variable_get(:@_remotes) ).to eq remotes
    end

    it "initializes a Remote with each remote" do
      deployment = define_deployment "multi", :multi_target do
        remotes [
          { hostname: 'web01' },
          { hostname: 'web02' }
        ]
      end

      expect( Statistrano::Remote ).to receive(:new).exactly(2).times
      deployment.remotes
    end

    it "merges remote data with global data" do
      deployment = define_deployment "multi", :multi_target do
        remote_dir "remote_dir"
        remotes [
          { hostname: 'web01', remote_dir: 'web01_remote_dir' }
        ]
      end

      expect( Statistrano::Remote ).to receive(:new)
        .with(default_options.merge({hostname: 'web01', remote_dir: 'web01_remote_dir'}))
      deployment.remotes
    end
  end

  describe "#deploy" do
    context "when check_git set to true" do
      before :each do
        @subject = define_deployment "multi", :multi_target do
          check_git  true
          git_branch 'master'
        end

        allow( Asgit ).to receive(:working_tree_clean?).and_return(true)
        allow( Asgit ).to receive(:current_branch).and_return('master')
        allow( Asgit ).to receive(:remote_up_to_date?).and_return(true)
      end

      it "exits if the working_tree is dirty" do
        allow( Asgit ).to receive(:working_tree_clean?).and_return(false)

        expect{
          @subject.deploy
        }.to raise_error(SystemExit)
      end

      it "exits if current_branch is not set to branch" do
        allow( Asgit ).to receive(:current_branch).and_return('something_else')

        expect{
          @subject.deploy
        }.to raise_error(SystemExit)
      end

      it "exits if out of sync with remote" do
        allow( Asgit ).to receive(:remote_up_to_date?).and_return(false)

        expect{
          @subject.deploy
        }.to raise_error(SystemExit)
      end
    end

    context "when build task is defined as a Proc" do
      context "when build task returns hash" do
        it "passes hash to build" do
          subject = define_deployment "multi", :multi_target do
            build_task do
              {foo: 'bar'}
            end
            remotes [{one: 'two'}]
          end
          remote   = instance_double("Statistrano::Remote")
          releaser = instance_double("Statistrano::Deployment::Releaser::Revisions")
          allow( Statistrano::Remote ).to receive(:new)
                                                               .and_return(remote)
          allow( Statistrano::Deployment::Releaser::Revisions ).to receive(:new)
                                                                 .and_return(releaser)

          expect( releaser ).to receive(:create_release)
                            .with( remote, {foo: 'bar'})

          subject.deploy
        end
      end

      context "when build task returns foo" do
        it "passes a blank hash to create_release" do
          subject = define_deployment "multi", :multi_target do
            build_task do
              'foo'
            end
            remotes [{one: 'two'}]
          end
          remote   = instance_double("Statistrano::Remote")
          releaser = instance_double("Statistrano::Deployment::Releaser::Revisions")
          allow( Statistrano::Remote ).to receive(:new)
                                                               .and_return(remote)
          allow( Statistrano::Deployment::Releaser::Revisions ).to receive(:new)
                                                                 .and_return(releaser)

          expect( releaser ).to receive(:create_release)
                            .with( remote, {})

          subject.deploy
        end
      end
    end

    it "runs create_release for each remote" do
      @subject = define_deployment "multi", :multi_target do
        build_task 'nil:bar'
        post_deploy_task 'foo:bar'
        remotes [{remote: 'one'},{remote: 'two'}]
      end
      task_double = double(invoke: nil)
      allow( Rake::Task ).to receive(:[])
                         .and_return(task_double)

      remote   = instance_double("Statistrano::Remote")
      releaser = instance_double("Statistrano::Deployment::Releaser::Revisions")
      allow( Statistrano::Remote ).to receive(:new)
                                                           .and_return(remote)
      allow( Statistrano::Deployment::Releaser::Revisions ).to receive(:new)
                                                           .and_return(releaser)

      expect( releaser ).to receive(:create_release)
                        .with(remote, {}).twice
      @subject.deploy
    end

    context "when post_deploy_task is a proc" do
      it "calls the post_deploy_task task" do
        subject     = define_deployment "multi", :multi_target
        task_double = double( call: 'foo' )
        config      = double("Statistrano::Config", build_task: -> {},
                                                    check_git: false,
                                                    options: { remotes: [] },
                                                    post_deploy_task: task_double)
        allow( subject ).to receive(:config).and_return(config)

        expect( task_double ).to receive(:call)
        subject.deploy
      end
    end
    context "when post_deploy_task is a string" do
      it "invokes the post_deploy_task once" do
        @subject = define_deployment "multi", :multi_target do
          build_task 'nil:bar'
          post_deploy_task 'foo:bar'
        end

        task_double      = double(invoke: nil)
        post_task_double = double
        allow( Rake::Task ).to receive(:[]).with('nil:bar')
                           .and_return(task_double)
        expect( Rake::Task ).to receive(:[]).with('foo:bar')
                            .and_return(post_task_double)
        expect( post_task_double ).to receive(:invoke).once

        @subject.deploy
      end
    end
  end

end