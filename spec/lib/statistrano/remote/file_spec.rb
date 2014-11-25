require 'spec_helper'

describe Statistrano::Remote::File do

  def stub_remote_file_to_exist
    expect( @remote ).to receive(:run) # the file doesn't exist
                     .with("[ -f /path ] && echo \"exists\"")
                     .and_return( HereOrThere::Response.new("exists\n",'',true) )
  end

  def stub_remote_file_to_not_exist
    expect( @remote ).to receive(:run) # the file doesn't exist
                     .with("[ -f /path ] && echo \"exists\"")
                     .and_return( HereOrThere::Response.new('','',true) )
  end

  describe "#initialize" do
    it "sets the given path" do
      subject = described_class.new "/path", :remote
      expect( subject.path ).to eq "/path"
    end
    it "sets the given remote" do
      subject = described_class.new "/path", :remote
      expect( subject.remote ).to eq :remote
    end
    it "sets the given permissions" do
      subject = described_class.new "/path", :remote, 660
      expect( subject.permissions ).to eq 660
    end
    it "defaults to 644 permissions if not set" do
      subject = described_class.new "/path", :remote
      expect( subject.permissions ).to eq 644
    end
  end

  describe "#content" do
    it "returns string of file content" do
      remote_double = instance_double("Statistrano::Remote")
      subject = described_class.new "/path", remote_double

      expect(remote_double).to receive(:run)
                           .with("cat /path")
                           .and_return(HereOrThere::Response.new("content","",true))
      expect( subject.content ).to eq "content"
    end

    it "returns an empty string if errors on remote" do
      remote_double = instance_double("Statistrano::Remote")
      subject = described_class.new "/path", remote_double

      expect(remote_double).to receive(:run)
                           .with("cat /path")
                           .and_return(HereOrThere::Response.new("content","error",false))
      expect( subject.content ).to eq ""
    end
  end

  describe "#update_content!" do
    before :each do
      @config  = double("Statistrano::Config", hostname: 'web01')
      @remote  = instance_double("Statistrano::Remote", config: @config )
      allow( @remote ).to receive(:run)
                      .and_return( HereOrThere::Response.new("",'',true) )
      @subject = described_class.new '/path', @remote
    end

    it "tests if file exists" do
      expect( @remote ).to receive(:run)
                       .with("[ -f /path ] && echo \"exists\"")
                       .and_return( HereOrThere::Response.new("exists\n",'',true) )
      @subject.update_content! "foooo"
    end

    context "when remote file doesn't exist" do
      before :each do
        stub_remote_file_to_not_exist
      end

      it "creates the file" do
        expect( @remote ).to receive(:run)
                         .with("touch /path " +
                               "&& chmod 644 /path")
                         .and_return( HereOrThere::Response.new("",'',true) )

        @subject.update_content! "content"
      end

      it "sets the content to the given content" do
        expect( @remote ).to receive(:run)
                         .with( "echo 'content' > /path" )
                         .and_return( HereOrThere::Response.new('','',true) )

        @subject.update_content! "content"
      end
    end

    context "when remote file already existed" do
      before :each do
        stub_remote_file_to_exist
      end
      it "sets the content to the given content" do
        expect( @remote ).to receive(:run)
                         .with( "echo 'content' > /path" )
                         .and_return( HereOrThere::Response.new('','',true) )

        @subject.update_content! "content"
      end
    end
  end

  describe "#destroy!" do
    it "removes the file" do
      config  = double("Statistrano::Config", hostname: 'web01')
      remote  = instance_double("Statistrano::Remote", config: config )
      allow( remote ).to receive(:run)
                      .and_return( HereOrThere::Response.new("",'',true) )
      subject = described_class.new '/path', remote

      expect(remote).to receive(:run).with("rm /path")
      subject.destroy!
    end
  end

end