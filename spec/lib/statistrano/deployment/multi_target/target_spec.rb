require 'spec_helper'

describe Statistrano::Deployment::MultiTarget::Target do

  let(:default_options) do
    { remote: 'web01' }
  end

  def create_ssh_double
    ssh_double = instance_double("HereOrThere::Remote::SSH")
    allow_any_instance_of( Statistrano::Config ).to receive(:ssh_session).and_return(ssh_double)
    return ssh_double
  end

  describe "#initialize" do
    it "assigns options hash to configuration" do
      subject = described_class.new default_options
      expect( subject.config.options[:remote] ).to eq default_options[:remote]
    end

    it "uses config.options defaults if option not given" do
      subject = described_class.new default_options
      expect( subject.config.user ).to be_nil
    end

    it "raises an error if no remote is given" do
      expect{
        described_class.new({user: 'woo'})
      }.to raise_error ArgumentError, 'a remote is required'
    end
  end

  describe "#run" do
    it "passes command to ssh_session#run" do
      ssh_double = create_ssh_double
      subject = described_class.new default_options

      expect( ssh_double ).to receive(:run).with('ls')
      subject.run 'ls'
    end

    it "logs the command if verbose is true" do
      ssh_double = create_ssh_double
      subject    = described_class.new default_options.merge verbose: true


      allow( ssh_double ).to receive(:run).with('ls')
      expect( Statistrano::Log ).to receive(:info)
                                .with( :web01, "running cmd: ls")
      subject.run 'ls'
    end
  end

  describe "#done" do
    it "passes close_session command to ssh_session" do
      ssh_double = create_ssh_double
      subject = described_class.new default_options

      expect( ssh_double ).to receive(:close_session)
      subject.done
    end
  end

  describe "#test_connection" do
    it "runs whoami on remote" do
      ssh_double = create_ssh_double
      allow(ssh_double).to receive(:close_session)
      subject    = described_class.new default_options

      expect( ssh_double ).to receive(:run).with('whoami')
                          .and_return( HereOrThere::Response.new("statistrano","",true))
      subject.test_connection
    end
    it "returns true if successful" do
      ssh_double = create_ssh_double
      allow(ssh_double).to receive(:close_session)
      subject    = described_class.new default_options

      expect( ssh_double ).to receive(:run).with('whoami')
                          .and_return( HereOrThere::Response.new("statistrano","",true))
      expect( subject.test_connection ).to be_truthy
    end
    it "returns false if fails" do
      ssh_double = create_ssh_double
      allow(ssh_double).to receive(:close_session)
      subject    = described_class.new default_options

      expect( ssh_double ).to receive(:run).with('whoami')
                          .and_return( HereOrThere::Response.new("","error",false))
      expect( subject.test_connection ).to be_falsy
    end
  end

  describe "#create_remote_dir" do
    it "runs mkdir command on remote" do
      ssh_double = create_ssh_double
      subject = described_class.new default_options

      expect( ssh_double ).to receive(:run)
                          .with("mkdir -p -m 770 /var/www/proj")
                          .and_return( HereOrThere::Response.new("","",true) )
      subject.create_remote_dir "/var/www/proj"
    end

    it "requires an absolute path" do
      ssh_double = create_ssh_double
      subject = described_class.new default_options

      expect {
        subject.create_remote_dir "var/www/proj"
      }.to raise_error ArgumentError, "path must be absolute"
    end

    context "when remote dir creation fails" do
      it "logs error & exits" do
        ssh_double = create_ssh_double
        subject = described_class.new default_options
        allow( ssh_double ).to receive(:run)
                            .with("mkdir -p -m 770 /var/www/proj")
                            .and_return( HereOrThere::Response.new("","oh noes",false) )

        expect( Statistrano::Log ).to receive(:error)
                                  .with( "Unable to create directory '/var/www/proj' on web01",
                                          "oh noes")
        expect{
          subject.create_remote_dir "/var/www/proj"
        }.to raise_error SystemExit
      end
    end
  end

  describe "#rsync_to_remote" do
    it "runs command to rsync local to remote" do
      subject = described_class.new default_options

      expect( Statistrano::Shell ).to receive(:run_local)
                                 .with("rsync -aqz --delete-after --chmod g=rwx " +
                                       "-e ssh local_path/ " +
                                       "web01:remote_path/")
                                 .and_return( HereOrThere::Response.new("","",true) )

      subject.rsync_to_remote 'local_path', 'remote_path'
    end

    it "corrects for adding a trailing slash to local_path or remote_path" do
      subject = described_class.new default_options

      expect( Statistrano::Shell ).to receive(:run_local)
                                 .with("rsync -aqz --delete-after --chmod g=rwx " +
                                       "-e ssh local_path/ " +
                                       "web01:remote_path/")
                                 .and_return( HereOrThere::Response.new("","",true) )

      subject.rsync_to_remote 'local_path/', 'remote_path/'
    end

    it "logs error if rsync command fails" do
      subject = described_class.new default_options
      expect( Statistrano::Shell ).to receive(:run_local)
                                 .and_return( HereOrThere::Response.new("","",false) )

      expect( Statistrano::Log ).to receive(:error)
      subject.rsync_to_remote 'local_path', 'remote_path'
    end

    it "returns the response" do
      subject = described_class.new default_options
      response = HereOrThere::Response.new("woo","",true)
      expect( Statistrano::Shell ).to receive(:run_local)
                                 .and_return( response )

      expect( subject.rsync_to_remote('local_path','remote_path') ).to eq response
    end
  end

end