require 'spec_helper'
require 'ostruct'

describe Statistrano::Remote do

  let(:default_options) do
    {
      hostname:         'web01',
      verbose:          false,
      user:             nil,
      passowrd:         nil,
      dir_permissions:  755,
      file_permissions: 644,
      rsync_flags:      '-aqz --delete-after'
    }
  end

  let(:default_config) do
    config default_options
  end

  def create_ssh_double
    ssh_double = instance_double("HereOrThere::Remote::SSH")
    allow( HereOrThere::Remote ).to receive(:session).and_return(ssh_double)
    return ssh_double
  end

  def config options
    OpenStruct.new( options )
  end

  describe "#initialize" do
    it "assigns given config to config" do
      subject = described_class.new default_config
      expect( subject.config ).to eq default_config
    end

    it "raises an error if no hostname is given" do
      expect{
        described_class.new( Struct.new(:hostname).new )
      }.to raise_error ArgumentError, 'a hostname is required'
    end
  end

  describe "#run" do
    it "passes command to ssh_session#run" do
      ssh_double = create_ssh_double
      subject    = described_class.new default_config

      expect( ssh_double ).to receive(:run).with('ls')
      subject.run 'ls'
    end

    it "logs the command if verbose is true" do
      ssh_double = create_ssh_double
      subject    = described_class.new config default_options.merge verbose: true


      allow( ssh_double ).to receive(:run).with('ls')
      expect( Statistrano::Log ).to receive(:info)
                                .with( :web01, "running cmd: ls")
      subject.run 'ls'
    end
  end

  describe "#done" do
    it "passes close_session command to ssh_session" do
      ssh_double = create_ssh_double
      subject    = described_class.new default_config

      expect( ssh_double ).to receive(:close_session)
      subject.done
    end
  end

  describe "#test_connection" do
    it "runs whoami on remote" do
      ssh_double = create_ssh_double
      allow(ssh_double).to receive(:close_session)
      subject    = described_class.new default_config

      expect( ssh_double ).to receive(:run).with('whoami')
                          .and_return( HereOrThere::Response.new("statistrano","",true))
      subject.test_connection
    end
    it "returns true if successful" do
      ssh_double = create_ssh_double
      allow(ssh_double).to receive(:close_session)
      subject    = described_class.new default_config

      expect( ssh_double ).to receive(:run).with('whoami')
                          .and_return( HereOrThere::Response.new("statistrano","",true))
      expect( subject.test_connection ).to be_truthy
    end
    it "returns false if fails" do
      ssh_double = create_ssh_double
      allow(ssh_double).to receive(:close_session)
      subject    = described_class.new default_config

      expect( ssh_double ).to receive(:run).with('whoami')
                          .and_return( HereOrThere::Response.new("","error",false))
      expect( subject.test_connection ).to be_falsy
    end
  end

  describe "#create_remote_dir" do
    it "runs mkdir command on remote" do
      ssh_double = create_ssh_double
      subject = described_class.new default_config

      expect( ssh_double ).to receive(:run)
                          .with("mkdir -p -m 755 /var/www/proj")
                          .and_return( HereOrThere::Response.new("","",true) )
      subject.create_remote_dir "/var/www/proj"
    end

    it "requires an absolute path" do
      ssh_double = create_ssh_double
      subject = described_class.new default_config

      expect {
        subject.create_remote_dir "var/www/proj"
      }.to raise_error ArgumentError, "path must be absolute"
    end

    it "uses the set dir_permissions" do
      ssh_double = create_ssh_double
      subject = described_class.new config default_options.merge dir_permissions: 644

      expect( ssh_double ).to receive(:run)
                          .with("mkdir -p -m 644 /var/www/proj")
                          .and_return( HereOrThere::Response.new("","",true) )
      subject.create_remote_dir "/var/www/proj"
    end

    context "when remote dir creation fails" do
      it "logs error & exits" do
        ssh_double = create_ssh_double
        subject = described_class.new default_config
        allow( ssh_double ).to receive(:run)
                            .with("mkdir -p -m 755 /var/www/proj")
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
      subject = described_class.new default_config

      expect( Statistrano::Shell ).to receive(:run_local)
                                  .with("rsync -aqz --delete-after " +
                                        "--chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r " +
                                        "-e ssh local_path/ " +
                                        "web01:remote_path/")
                                 .and_return( HereOrThere::Response.new("","",true) )

      subject.rsync_to_remote 'local_path', 'remote_path'
    end

    it "corrects for adding a trailing slash to local_path or remote_path" do
      subject = described_class.new default_config

      expect( Statistrano::Shell ).to receive(:run_local)
                                 .with("rsync -aqz --delete-after " +
                                        "--chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r " +
                                        "-e ssh local_path/ " +
                                        "web01:remote_path/")
                                 .and_return( HereOrThere::Response.new("","",true) )

      subject.rsync_to_remote 'local_path/', 'remote_path/'
    end

    it "uses the set dir_permissions & file_permissions" do
      subject = described_class.new config default_options.merge dir_permissions: 644, file_permissions: 755

      expect( Statistrano::Shell ).to receive(:run_local)
                                 .with("rsync -aqz --delete-after " +
                                        "--chmod=Du=rw,Dg=r,Do=r,Fu=rwx,Fg=rx,Fo=rx " +
                                        "-e ssh local_path/ " +
                                        "web01:remote_path/")
                                 .and_return( HereOrThere::Response.new("","",true) )

      subject.rsync_to_remote 'local_path/', 'remote_path/'
    end

    it "uses the set rsync_flags" do
      subject = described_class.new config default_options.merge rsync_flags: "-aqz"

      expect( Statistrano::Shell ).to receive(:run_local)
                                 .with("rsync -aqz " +
                                        "--chmod=Du=rwx,Dg=rx,Do=rx,Fu=rw,Fg=r,Fo=r " +
                                        "-e ssh local_path/ " +
                                        "web01:remote_path/")
                                 .and_return( HereOrThere::Response.new("","",true) )

      subject.rsync_to_remote 'local_path/', 'remote_path/'
    end

    it "logs error if rsync command fails" do
      subject = described_class.new default_config
      expect( Statistrano::Shell ).to receive(:run_local)
                                 .and_return( HereOrThere::Response.new("","",false) )

      expect( Statistrano::Log ).to receive(:error)
      subject.rsync_to_remote 'local_path', 'remote_path'
    end

    it "returns the response" do
      subject = described_class.new default_config
      response = HereOrThere::Response.new("woo","",true)
      expect( Statistrano::Shell ).to receive(:run_local)
                                 .and_return( response )

      expect( subject.rsync_to_remote('local_path','remote_path') ).to eq response
    end
  end

end
