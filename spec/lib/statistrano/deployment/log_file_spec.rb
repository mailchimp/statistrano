require 'spec_helper'

describe Statistrano::Deployment::LogFile do

  before :each do
    config  = double("Statistrano::Config", remote_dir: '/remote_dir')
    @remote = instance_double("Statistrano::Remote", config: config)
  end

  describe "#initialize" do

    it "sets :remote to the given remote" do
      subject = described_class.new 'foo/bar', @remote
      expect( subject.remote ).to eq @remote
    end
    it "sets resolved_path to given path if absolute" do
      subject = described_class.new '/var/log', @remote
      expect( subject.resolved_path ).to eq '/var/log'
    end
    it "sets resolved_path relative to remote.config.remote_dir if relative" do
      subject = described_class.new 'var/log', @remote
      expect( subject.resolved_path ).to eq '/remote_dir/var/log'
    end
    it "sets file to Remote::File created with resolved_path and remote" do
      expect( Statistrano::Remote::File ).to receive(:new)
                                         .with( '/var/log', @remote )

      described_class.new '/var/log', @remote
    end
  end

  describe "#append!" do
    it "calls #append_content! on Remote::File with entry converted to json" do
      remote_file_double = instance_double("Statistrano::Remote::File")
      allow( Statistrano::Remote::File ).to receive(:new)
                                        .with( '/var/log', @remote )
                                        .and_return(remote_file_double)
      subject = described_class.new '/var/log', @remote

      expect( remote_file_double ).to receive(:append_content!)
                                  .with('{"log":"entry"}')

      subject.append! log: 'entry'
    end
  end

  describe "#last_entry" do

    before :each do
      @remote_file_double = instance_double("Statistrano::Remote::File")
      allow( Statistrano::Remote::File ).to receive(:new)
                                        .with( '/var/log', @remote )
                                        .and_return(@remote_file_double)
      @subject = described_class.new '/var/log', @remote
    end

    it "returns hash of last entry data" do
      allow( @remote_file_double ).to receive(:content)
                                  .and_return "{\"log\":1}\n{\"log\":2}"

      expect( @subject.last_entry ).to eq log: 2
    end

    it "returns empty hash if no entries" do
      allow( @remote_file_double ).to receive(:content)
                                  .and_return ""

      expect( @subject.last_entry ).to eq({})
    end
  end

  describe "#tail" do
  end

end
