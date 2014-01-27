require 'spec_helper'

describe Statistrano::Deployment::MultiTarget::Releaser do

  let(:default_arguments) do
    {
      remote_dir: '/var/www/proj',
      local_dir: 'build'
    }
  end

  let(:default_target_config_responses) do
    {
      remote_dir:    nil,
      local_dir:     nil,
      release_count: nil,
      release_dir:   nil,
      public_dir:    nil
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
      config  = double("Statistrano::Config", default_target_config_responses )
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      subject = described_class.new default_arguments
      allow( target ).to receive(:run)
                     .and_return( HereOrThere::Response.new("","",true) )

      expect( target ).to receive(:create_remote_dir)
                      .with( '/var/www/proj/releases' )
      expect( target ).to receive(:create_remote_dir)
                      .with( File.join( '/var/www/proj/releases', subject.release_name ) )
      subject.setup_release_path target
    end
    context "with an existing release" do
      it "copies existing 'current' release to release_path" do
        config  = double("Statistrano::Config", default_target_config_responses )
        target  = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
        subject = described_class.new default_arguments
        release_path = File.join( '/var/www/proj/releases', subject.release_name )
        allow( target ).to receive(:run)
                       .and_return( HereOrThere::Response.new("","",true) )

        expect( target ).to receive(:create_remote_dir)
                        .with( '/var/www/proj/releases' )
        expect( target ).to receive(:create_remote_dir)
                        .with( release_path )

        allow( target ).to receive(:run).with("readlink /var/www/proj/current")
                       .and_return( HereOrThere::Response.new("/var/www/proj/releases/1234","",true) )
        expect( target ).to receive(:run)
                        .with("cp -a /var/www/proj/releases/1234 #{release_path}")
        subject.setup_release_path target
      end
    end
    context "with no existing releases" do
      it "does not attempt to copy release to release_path" do
        config  = double("Statistrano::Config", default_target_config_responses )
        target  = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
        subject = described_class.new default_arguments
        release_path = File.join( '/var/www/proj/releases', subject.release_name )
        allow( target ).to receive(:run)
                       .and_return( HereOrThere::Response.new("","",true) )

        expect( target ).to receive(:create_remote_dir)
                        .with( '/var/www/proj/releases' )
        expect( target ).to receive(:create_remote_dir)
                        .with( release_path )

        allow( target ).to receive(:run).with("readlink /var/www/proj/current")
                       .and_return( HereOrThere::Response.new("","",true) )
        expect( target ).not_to receive(:run)
                        .with("cp -a /var/www/proj/releases/ #{release_path}")
        subject.setup_release_path target
      end
    end
  end

  describe "#rsync_to_remote" do
    it "calls rsync_to_remote on the target with the local_dir & release_path" do
      config  = double("Statistrano::Config", default_target_config_responses )
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      subject = described_class.new default_arguments

      allow( Dir ).to receive(:pwd).and_return('/local')
      expect( target ).to receive(:rsync_to_remote)
                      .with( '/local/build', File.join( '/var/www/proj/releases', subject.release_name ) )
                      .and_return( HereOrThere::Response.new("","",true) )
      subject.rsync_to_remote target
    end
  end

  describe "#symlink_release" do
    it "runs symlink command on target" do
      config  = double("Statistrano::Config", default_target_config_responses )
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      subject = described_class.new default_arguments
      release_path = File.join( '/var/www/proj/releases', subject.release_name )

      expect( target ).to receive(:run)
                      .with( "ln -nfs #{release_path} /var/www/proj/current" )
      subject.symlink_release target
    end
  end

  describe "#prune_releases" do
    it "removes releases not tracked in manifest" do
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      manifest = instance_double("Statistrano::Deployment::MultiTarget::Manifest")
      subject  = described_class.new default_arguments
      releases = [ Time.now.to_i.to_s,
                  (Time.now.to_i + 1 ).to_s,
                  (Time.now.to_i + 2 ).to_s ]
      extra_release = (Time.now.to_i + 3).to_s

      allow(target).to receive(:run)
                    .with("ls -m /var/www/proj/releases")
                    .and_return( HereOrThere::Response.new( (releases + [extra_release]).join(','), '', true ) )
      allow(target).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("",'',true) )
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
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
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
      allow(target).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("",'',true) )

      # this is gnarly but we need to test against
      # the manifest release data because of the block in
      # Manifest#remove_if
      allow(target).to receive(:run)
                   .with("cat /var/www/proj/manifest.json")
                   .and_return( HereOrThere::Response.new("[#{ releases.map{ |r| "{\"release\": \"#{r}\"}" }.join(',') }]",'',true) )

      expect(target).to receive(:run)
                   .with("rm -rf /var/www/proj/releases/#{releases.first}")
      expect(manifest).to receive(:save!)
      subject.prune_releases target

      # our expectation is for manifest data to be missing
      # the release that is to be removed
      expect(manifest.data).to eq releases[1..-1].map {|r| {release: r}}
    end

    it "skips removing a release if it is currently symlinked" do
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
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

      allow(target).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("/var/www/proj/releases/#{releases.first}\n",'',true) )
      expect(target).not_to receive(:run)
                    .with("rm -rf /var/www/proj/releases/#{releases.first}")
      expect(manifest).to receive(:save!)

      subject.prune_releases target
    end
  end

  describe "#add_release_to_manifest" do
    it "adds release to manifest & saves" do
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
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
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
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

  describe "#create_release" do
    it "runs through the pipeline" do
      # stupid spec for now
      target  = instance_double("Statistrano::Deployment::MultiTarget::Target")
      subject = described_class.new default_arguments

      expect(subject).to receive(:setup_release_path).with(target)
      expect(subject).to receive(:rsync_to_remote).with(target)
      expect(subject).to receive(:symlink_release).with(target)
      expect(subject).to receive(:add_release_to_manifest).with(target, arbitrary: 'data')
      expect(subject).to receive(:prune_releases).with(target)

      subject.create_release target, arbitrary: 'data'
    end
  end

  describe "#list_releases" do
    it "returns manifest data of releases" do
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      subject  = described_class.new default_arguments
      manifest = instance_double("Statistrano::Deployment::MultiTarget::Manifest")
      allow( Statistrano::Deployment::MultiTarget::Manifest ).to receive(:new)
                                                             .and_return(manifest)

      release_data = [{release:"one"},{release:"two"}]
      allow(manifest).to receive(:data)
                     .and_return( release_data + [{not_release:"foo"}])

      expect( subject.list_releases(target) ).to match_array release_data
    end
    it "sorts releases by release data (newest first)" do
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      subject  = described_class.new default_arguments
      manifest = instance_double("Statistrano::Deployment::MultiTarget::Manifest")
      allow( Statistrano::Deployment::MultiTarget::Manifest ).to receive(:new)
                                                             .and_return(manifest)

      release_one   = ( Time.now.to_i + 0 ).to_s
      release_two   = ( Time.now.to_i + 1 ).to_s
      release_three = ( Time.now.to_i + 2 ).to_s

      release_data = [{release:release_one},{release:release_three},{release:release_two}]
      allow(manifest).to receive(:data)
                     .and_return( release_data + [{not_release:"foo"}])

      expect( subject.list_releases(target) ).to eq [{release:release_three},{release:release_two},{release:release_one}]
    end
  end

  describe "#rollback_release" do
    it "symlinks the previous release" do
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      subject  = described_class.new default_arguments
      manifest = instance_double("Statistrano::Deployment::MultiTarget::Manifest")
      allow( Statistrano::Deployment::MultiTarget::Manifest ).to receive(:new)
                                                             .with( '/var/www/proj', target )
                                                             .and_return(manifest)


      release_one   = ( Time.now.to_i + 0 ).to_s
      release_two   = ( Time.now.to_i + 1 ).to_s
      release_three = ( Time.now.to_i + 2 ).to_s

      allow( manifest ).to receive(:data)
                       .and_return([
                          {release: release_one},
                          {release: release_two},
                          {release: release_three}
                        ])
      allow( target ).to receive(:run)
      allow(target).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("",'',true) )
      allow( manifest ).to receive(:remove_if)
      allow( manifest ).to receive(:save!)

      expect( subject ).to receive(:symlink_release)
                       .with( target, release_two )

      subject.rollback_release target
    end

    it "removes the newest release from disk on target" do
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      subject  = described_class.new default_arguments
      manifest = instance_double("Statistrano::Deployment::MultiTarget::Manifest")
      allow( Statistrano::Deployment::MultiTarget::Manifest ).to receive(:new)
                                                             .with( '/var/www/proj', target )
                                                             .and_return(manifest)

      release_one   = ( Time.now.to_i + 0 ).to_s
      release_two   = ( Time.now.to_i + 1 ).to_s
      release_three = ( Time.now.to_i + 2 ).to_s

      allow( manifest ).to receive(:data)
                       .and_return([
                          {release: release_one},
                          {release: release_two},
                          {release: release_three}
                        ])


      allow( subject ).to receive(:symlink_release)
                      .with( target, release_two )
      allow( manifest ).to receive(:remove_if)
      allow( manifest ).to receive(:save!)

      allow(target).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("",'',true) )
      expect( target ).to receive(:run)
                      .with("rm -rf /var/www/proj/releases/#{release_three}")

      subject.rollback_release target
    end

    it "removes the newest release from the manifest" do
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      subject  = described_class.new default_arguments
      manifest = Statistrano::Deployment::MultiTarget::Manifest.new '/var/www/proj', target
      allow( Statistrano::Deployment::MultiTarget::Manifest ).to receive(:new)
                                                             .with( '/var/www/proj', target )
                                                             .and_return(manifest)


      release_one   = ( Time.now.to_i + 0 ).to_s
      release_two   = ( Time.now.to_i + 1 ).to_s
      release_three = ( Time.now.to_i + 2 ).to_s
      releases      = [release_three,release_two,release_one]
      allow( target ).to receive(:run)
      allow(target).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("",'',true) )


      # this is gnarly but we need to test against
      # the manifest release data because of the block in
      # Manifest#remove_if
      allow(target).to receive(:run)
                   .with("cat /var/www/proj/manifest.json")
                   .and_return( HereOrThere::Response.new("[#{ releases.map{ |r| "{\"release\": \"#{r}\"}" }.join(',') }]",'',true) )

      allow( subject ).to receive(:symlink_release)
                       .with( target, release_two )

      expect( manifest ).to receive(:save!)
      subject.rollback_release target
      expect( manifest.data ).to eq releases[1..-1].map {|r| {release: r}}
    end

    it "errors if there is only one release" do
      config   = double("Statistrano::Config", default_target_config_responses )
      target   = instance_double("Statistrano::Deployment::MultiTarget::Target", config: config )
      subject  = described_class.new default_arguments
      manifest = instance_double("Statistrano::Deployment::MultiTarget::Manifest")
      allow( Statistrano::Deployment::MultiTarget::Manifest ).to receive(:new)
                                                             .and_return(manifest)

      release_one   = ( Time.now.to_i + 0 ).to_s
      allow( manifest ).to receive(:data)
                       .and_return([
                          { release: release_one }
                        ])

      expect( Statistrano::Log ).to receive(:error)
      subject.rollback_release target
    end
  end

end