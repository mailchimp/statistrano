require 'spec_helper'

describe Statistrano::Deployment::Strategy::InvokeTasks do

  before :each do
    class Subject
      include Statistrano::Deployment::Strategy::InvokeTasks
    end
  end

  let(:subject) { Subject.new }

  describe "#invoke_post_deploy_task" do
    it "calls_or_invokes the post_deploy_task" do
      allow( subject ).to receive_message_chain(:config, :post_deploy_task)
                      .and_return "foo"
      expect( subject ).to receive(:call_or_invoke_task).with "foo"
      subject.invoke_post_deploy_task
    end
  end

  describe "#invoke_build_task" do
    it "calls_or_invokes the build_task" do
      allow( subject ).to receive_message_chain(:config, :build_task)
                      .and_return "foo"
      expect( subject ).to receive(:call_or_invoke_task).with "foo"
      subject.invoke_build_task
    end
  end

  describe "#call_or_invoke_task" do
    it "calls the task if it is a proc" do
      expect( subject.call_or_invoke_task( -> { "hello" } ) ).to eq "hello"
    end

    it "invokes a rake task if it is a string" do
      rake_double = double("Rake::Task")
      expect( Rake::Task ).to receive(:[])
                          .with("hello")
                          .and_return( rake_double )
      expect( rake_double ).to receive(:invoke)

      subject.call_or_invoke_task("hello")
    end

    it "catches exceptions and then aborts" do
      proc_raises_exception = -> { raise Exception, "ermagerd" }

      expect( Statistrano::Log ).to receive(:error)
                                .with "exiting due to error in task",
                                      "Exception: ermagerd"

      expect {
        subject.call_or_invoke_task(proc_raises_exception)
      }.to raise_error SystemExit
    end
  end

end