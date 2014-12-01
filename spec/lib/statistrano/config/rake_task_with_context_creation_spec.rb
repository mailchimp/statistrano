require 'spec_helper'

describe Statistrano::Config::RakeTaskWithContextCreation do

  before :each do
    Subject = Class.new
    Subject.send(:include, described_class)
  end

  describe "::included" do
    it "creates user_task_namespaces method defaulting to []" do
      expect( Subject.new.methods ).to include :user_task_namespaces
      expect( Subject.new.user_task_namespaces ).to eq []
    end

    it "creates user_tasks method defaulting to []" do
      expect( Subject.new.methods ).to include :user_tasks
      expect( Subject.new.user_tasks ).to eq []
    end
  end

  describe "#task" do
    it "adds a task to the user_tasks store with name and namespaces" do
      subject = Subject.new
      block   = lambda { }
      subject.task 'hello', &block

      expect( subject.user_tasks ).to include name: 'hello',
                                              namespaces: [],
                                              block: block
    end

    it "adds optional desc to task" do
      subject = Subject.new
      block   = lambda { }
      subject.task 'hello', 'I a method', &block

      expect( subject.user_tasks ).to include name: 'hello',
                                              desc: 'I a method',
                                              namespaces: [],
                                              block: block
    end
  end

  describe "#namespace" do
    it "evaluates given block appending the namespaces" do
      subject = Subject.new
      block   = lambda { }

      subject.namespace 'hello' do
        task 'world', &block

        namespace 'foo' do
          task 'bar',  &block
          task 'bang', &block
        end
      end

      expect( subject.user_tasks ).to include name: 'world',
                                              namespaces: ['hello'],
                                              block: block

      expect( subject.user_tasks ).to include name: 'bar',
                                              namespaces: ['hello', 'foo'],
                                              block: block

      expect( subject.user_tasks ).to include name: 'bang',
                                              namespaces: ['hello', 'foo'],
                                              block: block
    end
  end

end
