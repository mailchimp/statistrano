require 'spec_helper'

describe Statistrano::Deployment::MultiTarget::Releaser do

  let(:default_arguments) do
    {
      remote_dir: '/var/www/proj',
      local_dir: 'build'
    }
  end

  describe "#initialize" do
    it "assigns options hash to configuration" do
      subject = described_class.new default_arguments.merge(release_count: 10)
      expect( subject.config.release_count ).to eq 10
    end

    it "uses config.options defaults if option not given" do
      subject = described_class.new default_arguments
      expect( subject.config.release_dir ).to eq "releases"
    end

    it "requires a remote_dir to be set" do
      args = default_arguments.dup
      args.delete(:remote_dir)
      expect{
        described_class.new args
      }.to raise_error ArgumentError, "a remote_dir is required"
    end

    it "requires a local_dir to be set" do
      args = default_arguments.dup
      args.delete(:local_dir)
      expect{
        described_class.new args
      }.to raise_error ArgumentError, "a local_dir is required"
    end

    it "generates release_name from current time" do
      time = Time.now
      allow( Time ).to receive(:now).and_return(time)
      subject = described_class.new default_arguments

      allow( Time ).to receive(:now).and_return(time + 1)
      expect( Time.now ).not_to eq time # ensure that the time + 1 works
      expect( subject.release_name ).to eq time.to_i.to_s
    end
  end

  describe "#setup_release_path" do
    it "creates the release_path on the target" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new default_arguments

      expect( target ).to receive(:create_remote_dir)
                      .with( File.join( '/var/www/proj/releases', subject.release_name ) )
      subject.setup_release_path target
    end
  end

  describe "#rsync_to_remote" do
    it "calls rsync_to_remote on the target with the local_dir & release_path" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new default_arguments

      allow( Dir ).to receive(:pwd).and_return('/local')
      expect( target ).to receive(:rsync_to_remote)
                      .with( '/local/build', File.join( '/var/www/proj/releases', subject.release_name ) )
      subject.rsync_to_remote target
    end
  end

  describe "#symlink_release" do
    it "runs symlink command on target" do
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new default_arguments
      release_path = File.join( '/var/www/proj/releases', subject.release_name )

      expect( target ).to receive(:run)
                      .with( "ln -nfs #{release_path} /var/www/proj/current" )
      subject.symlink_release target
    end
  end

  describe "#prune_releases" do
    it "removes releases not tracked in manifest" do
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target")
      manifest = instance_double("Statistrano::Deployment::MultiTarget::Manifest")
      subject  = described_class.new default_arguments
      releases = [ Time.now.to_i.to_s,
                  (Time.now.to_i + 1 ).to_s,
                  (Time.now.to_i + 2 ).to_s ]
      extra_release = (Time.now.to_i + 3).to_s

      allow(target).to receive(:run)
                    .with("ls -m /var/www/proj/releases")
                    .and_return( HereOrThere::Response.new( (releases + [extra_release]).join(','), '', true ) )
      allow( Statistrano::Deployment::MultiTarget::Manifest ).to receive(:new)
                                                             .and_return(manifest)
      allow(manifest).to receive(:data)
                      .and_return(releases.map { |r| {release: r} })


      expect(target).to receive(:run)
                    .with("rm -rf /var/www/proj/releases/#{extra_release}")
      expect(manifest).to receive(:save!)
      subject.prune_releases target
    end

    it "removes older releases beyond release count from remote & manifest" do
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject  = described_class.new default_arguments.merge( release_count: 2 )
      manifest = Statistrano::Deployment::MultiTarget::Manifest.new '/var/www/proj', target
      allow( Statistrano::Deployment::MultiTarget::Manifest ).to receive(:new)
                                                             .with( '/var/www/proj', target )
                                                             .and_return(manifest)
      releases = [ Time.now.to_i.to_s,
                  (Time.now.to_i + 1 ).to_s,
                  (Time.now.to_i + 2 ).to_s ]

      allow(target).to receive(:run)
                   .with("ls -m /var/www/proj/releases")
                   .and_return( HereOrThere::Response.new( releases.join(','), '', true ) )

      # this is gnarly but we need to test against
      # the manifest release data because of the block in
      # Manifest#remove_if
      allow(target).to receive(:run)
                   .with("cat /var/www/proj/manifest.json")
                   .and_return( HereOrThere::Response.new("[#{ releases.map{ |r| "{\"release\": \"#{r}\"}" }.join(',') }]",'',true) )

      expect(target).to receive(:run)
                   .with("rm -rf /var/www/proj/releases/#{releases.last}")
      expect(manifest).to receive(:save!)
      subject.prune_releases target

      # our expectation is for manifest data to be missing
      # the release that is to be removed
      expect(manifest.data).to eq releases[0..1].map {|r| {release: r}}
    end
  end

  describe "#add_release_to_manifest" do
    it "adds release to manifest & saves" do
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target")
      manifest = instance_double("Statistrano::Deployment::MultiTarget::Manifest")
      allow( Statistrano::Deployment::MultiTarget::Manifest ).to receive(:new)
                                                             .and_return(manifest)
      subject = described_class.new default_arguments

      expect(manifest).to receive(:push)
                      .with( release: subject.release_name )
      expect(manifest).to receive(:save!)
      subject.add_release_to_manifest target
    end

    it "merges build_data to release in manifest" do
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target")
      manifest = instance_double("Statistrano::Deployment::MultiTarget::Manifest")
      allow( Statistrano::Deployment::MultiTarget::Manifest ).to receive(:new)
                                                             .and_return(manifest)
      subject = described_class.new default_arguments

      expect(manifest).to receive(:push)
                      .with( release: subject.release_name, arbitrary: 'data' )
      expect(manifest).to receive(:save!)

      subject.add_release_to_manifest target, arbitrary: 'data'
    end
  end

end