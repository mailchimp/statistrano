require 'spec_helper'

describe Statistrano::Deployment::Releaser::Revisions do

  let(:default_remote_config_responses) do
    {
      remote_dir:    '/var/www/proj',
      local_dir:     'build',
      release_count: 5,
      release_dir:   'releases',
      public_dir:    'current',
      log_file_path: nil
    }
  end

  describe "#initialize" do
    it "creates a release_name based on current time" do
      allow( Time ).to receive(:now).and_return(12345)
      subject = described_class.new
      expect( subject.release_name ).to eq "12345"
    end
  end

  describe "#setup_release_path" do
    context "with an existing release" do
      it "copies existing 'current' release to release_path" do
        config  = double("Statistrano::Config", default_remote_config_responses )
        remote  = instance_double("Statistrano::Remote", config: config )
        subject = described_class.new
        release_path = File.join( '/var/www/proj/releases', subject.release_name )
        allow( remote ).to receive(:run)
                       .and_return( HereOrThere::Response.new("","",true) )

        expect( remote ).to receive(:create_remote_dir)
                        .with( '/var/www/proj/releases' )
        expect( remote ).not_to receive(:create_remote_dir)
                        .with( release_path )

        allow( remote ).to receive(:run).with("readlink /var/www/proj/current")
                       .and_return( HereOrThere::Response.new("/var/www/proj/releases/1234","",true) )
        expect( remote ).to receive(:run)
                        .with("cp -a /var/www/proj/releases/1234 #{release_path}")
        subject.setup_release_path remote
      end
    end
    context "with no existing releases" do
      it "creates the release_path on the remote" do
        config  = double("Statistrano::Config", default_remote_config_responses )
        remote  = instance_double("Statistrano::Remote", config: config )
        subject = described_class.new
        allow( remote ).to receive(:run)
                       .and_return( HereOrThere::Response.new("","",true) )

        expect( remote ).to receive(:create_remote_dir)
                        .with( '/var/www/proj/releases' )
        expect( remote ).to receive(:create_remote_dir)
                        .with( File.join( '/var/www/proj/releases', subject.release_name ) )
        subject.setup_release_path remote
      end
    end
  end

  describe "#rsync_to_remote" do
    it "calls rsync_to_remote on the remote with the local_dir & release_path" do
      config  = double("Statistrano::Config", default_remote_config_responses )
      remote  = instance_double("Statistrano::Remote", config: config )
      subject = described_class.new

      allow( Dir ).to receive(:pwd).and_return('/local')
      expect( remote ).to receive(:rsync_to_remote)
                      .with( '/local/build', File.join( '/var/www/proj/releases', subject.release_name ) )
                      .and_return( HereOrThere::Response.new("","",true) )
      subject.rsync_to_remote remote
    end
  end

  describe "#symlink_release" do
    it "runs symlink command on remote" do
      config  = double("Statistrano::Config", default_remote_config_responses )
      remote  = instance_double("Statistrano::Remote", config: config )
      subject = described_class.new
      release_path = File.join( '/var/www/proj/releases', subject.release_name )

      expect( remote ).to receive(:run)
                      .with( "ln -nfs #{release_path} /var/www/proj/current" )
      subject.symlink_release remote
    end
  end

  describe "#prune_releases" do
    it "removes releases not tracked in manifest" do
      config   = double("Statistrano::Config", default_remote_config_responses )
      remote   = instance_double("Statistrano::Remote", config: config )
      manifest = instance_double("Statistrano::Deployment::Manifest")
      subject  = described_class.new
      releases = [ Time.now.to_i.to_s,
                  (Time.now.to_i + 1 ).to_s,
                  (Time.now.to_i + 2 ).to_s ]
      extra_release = (Time.now.to_i + 3).to_s

      allow(remote).to receive(:run)
                    .with("ls -m /var/www/proj/releases")
                    .and_return( HereOrThere::Response.new( (releases + [extra_release]).join(','), '', true ) )
      allow(remote).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("",'',true) )
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                .and_return(manifest)
      allow(manifest).to receive(:remove_if)
      allow(manifest).to receive(:data)
                     .and_return(releases.map { |r| {release: r} })


      expect(remote).to receive(:run)
                    .with("rm -rf /var/www/proj/releases/#{extra_release}")
      expect(manifest).to receive(:save!)
      subject.prune_releases remote
    end

    it "removes older releases beyond release count from remote & manifest" do
      config   = double("Statistrano::Config", default_remote_config_responses.merge(release_count: 2) )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = Statistrano::Deployment::Manifest.new '/var/www/proj', remote
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                             .with( '/var/www/proj', remote )
                                                             .and_return(manifest)
      releases = [ Time.now.to_i.to_s,
                  (Time.now.to_i + 1 ).to_s,
                  (Time.now.to_i + 2 ).to_s ]

      allow(remote).to receive(:run)
                   .with("ls -m /var/www/proj/releases")
                   .and_return( HereOrThere::Response.new( releases.join(','), '', true ) )
      allow(remote).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("",'',true) )

      # this is gnarly but we need to test against
      # the manifest release data because of the block in
      # Manifest#remove_if
      allow(remote).to receive(:run)
                   .with("cat /var/www/proj/manifest.json")
                   .and_return( HereOrThere::Response.new("[#{ releases.map{ |r| "{\"release\": \"#{r}\"}" }.join(',') }]",'',true) )

      expect(remote).to receive(:run)
                   .with("rm -rf /var/www/proj/releases/#{releases.first}")
      expect(manifest).to receive(:save!)
      subject.prune_releases remote

      # our expectation is for manifest data to be missing
      # the release that is to be removed
      expect(manifest.data).to eq releases[1..-1].map {|r| {release: r}}
    end

    it "skips removing a release if it is currently symlinked" do
      config   = double("Statistrano::Config", default_remote_config_responses.merge(release_count: 2) )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = Statistrano::Deployment::Manifest.new '/var/www/proj', remote
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                             .with( '/var/www/proj', remote )
                                                             .and_return(manifest)
      releases = [ Time.now.to_i.to_s,
                  (Time.now.to_i + 1 ).to_s,
                  (Time.now.to_i + 2 ).to_s ]

      allow(remote).to receive(:run)
                   .with("ls -m /var/www/proj/releases")
                   .and_return( HereOrThere::Response.new( releases.join(','), '', true ) )

      # this is gnarly but we need to test against
      # the manifest release data because of the block in
      # Manifest#remove_if
      allow(remote).to receive(:run)
                   .with("cat /var/www/proj/manifest.json")
                   .and_return( HereOrThere::Response.new("[#{ releases.map{ |r| "{\"release\": \"#{r}\"}" }.join(',') }]",'',true) )

      allow(remote).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("/var/www/proj/releases/#{releases.first}\n",'',true) )
      expect(remote).not_to receive(:run)
                    .with("rm -rf /var/www/proj/releases/#{releases.first}")
      expect(manifest).to receive(:save!)

      subject.prune_releases remote
    end
  end

  describe "#add_release_to_manifest" do
    it "adds release to manifest & saves" do
      config   = double("Statistrano::Config", default_remote_config_responses )
      remote   = instance_double("Statistrano::Remote", config: config )
      manifest = instance_double("Statistrano::Deployment::Manifest")
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                             .and_return(manifest)
      subject = described_class.new

      expect(manifest).to receive(:push)
                      .with( release: subject.release_name )
      expect(manifest).to receive(:save!)
      subject.add_release_to_manifest remote
    end

    it "merges build_data to release in manifest" do
      config   = double("Statistrano::Config", default_remote_config_responses )
      remote   = instance_double("Statistrano::Remote", config: config )
      manifest = instance_double("Statistrano::Deployment::Manifest")
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                             .and_return(manifest)
      subject = described_class.new

      expect(manifest).to receive(:push)
                      .with( release: subject.release_name, arbitrary: 'data' )
      expect(manifest).to receive(:save!)

      subject.add_release_to_manifest remote, arbitrary: 'data'
    end
  end

  describe "#create_release" do
    it "runs through the pipeline" do
      # stupid spec for now
      remote  = instance_double("Statistrano::Remote")
      subject = described_class.new

      expect(subject).to receive(:setup_release_path).with(remote)
      expect(subject).to receive(:rsync_to_remote).with(remote)
      expect(subject).to receive(:invoke_pre_symlink_task)
      expect(subject).to receive(:symlink_release).with(remote)
      expect(subject).to receive(:add_release_to_manifest).with(remote, arbitrary: 'data')
      expect(subject).to receive(:prune_releases).with(remote)

      subject.create_release remote, arbitrary: 'data'
    end

    it "aborts deploy if pre_symlink_task returns false or raises" do
      config   = double("Statistrano::Config", default_remote_config_responses.merge(
        pre_symlink_task: lambda { false }
      ))
      remote   = instance_double("Statistrano::Remote", config: config )
      subject = described_class.new

      expect(subject).to receive(:setup_release_path).with(remote)
      expect(subject).to receive(:rsync_to_remote).with(remote)
      expect(subject).to receive(:invoke_pre_symlink_task).and_call_original

      expect(subject).not_to receive(:symlink_release)
      expect(subject).not_to receive(:add_release_to_manifest)
      expect(subject).not_to receive(:prune_releases)

      expect {
        subject.create_release remote
      }.to raise_error SystemExit
    end
  end

  describe "#list_releases" do
    it "returns manifest data of releases" do
      config   = double("Statistrano::Config", default_remote_config_responses )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = instance_double("Statistrano::Deployment::Manifest")
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                             .and_return(manifest)

      release_data = [{release:"one"},{release:"two"}]
      allow(manifest).to receive(:data)
                     .and_return( release_data + [{not_release:"foo"}])

      expect( subject.list_releases(remote) ).to match_array release_data
    end
    it "sorts releases by release data (newest first)" do
      config   = double("Statistrano::Config", default_remote_config_responses )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = instance_double("Statistrano::Deployment::Manifest")
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                .and_return(manifest)

      release_one   = ( Time.now.to_i + 0 ).to_s
      release_two   = ( Time.now.to_i + 1 ).to_s
      release_three = ( Time.now.to_i + 2 ).to_s

      release_data = [{release:release_one},{release:release_three},{release:release_two}]
      allow(manifest).to receive(:data)
                     .and_return( release_data + [{not_release:"foo"}])

      expect( subject.list_releases(remote) ).to eq [{release:release_three},{release:release_two},{release:release_one}]
    end
  end

  describe "#current_release_data" do
    it "returns data from current release" do
      config   = double("Statistrano::Config", default_remote_config_responses )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = instance_double("Statistrano::Deployment::Manifest")
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                .and_return(manifest)

      manifest_data = [{release: 'first', foo: 'bar'},{release: 'current', random: 'data'}]
      allow(manifest).to receive(:data)
                     .and_return(manifest_data)

      expect( subject.current_release_data(remote) ).to eq release:'current', random:'data'
    end

    it "merges data from log if log_file_path given" do
      config   = double("Statistrano::Config", default_remote_config_responses.merge(log_file_path: '/var/log') )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = instance_double("Statistrano::Deployment::Manifest")
      log_file = instance_double("Statistrano::Deployment::LogFile")
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                .and_return(manifest)
      allow( Statistrano::Deployment::LogFile ).to receive(:new)
                                               .with('/var/log', remote)
                                               .and_return(log_file)

      manifest_data = [{release: 'first', foo: 'bar'},{release: 'current', random: 'data'}]
      allow(manifest).to receive(:data)
                     .and_return(manifest_data)
      allow(log_file).to receive(:last_entry)
                     .and_return name:   'current',
                                 log:    'data-current',
                                 nested: {
                                  data: 'nested'
                                 }

      expect( subject.current_release_data(remote) ).to eq release:'current',
                                                           random: 'data',
                                                           name:   'current',
                                                           log:    'data-current',
                                                           nested: {
                                                            data: 'nested'
                                                           }
    end

    it "handles an empty log file if log_file_path is given" do
      config   = double("Statistrano::Config", default_remote_config_responses.merge(log_file_path: '/var/log') )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = instance_double("Statistrano::Deployment::Manifest")
      log_file = instance_double("Statistrano::Remote::File")
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                .and_return(manifest)
      allow( Statistrano::Remote::File ).to receive(:new)
                                        .with('/var/log', remote)
                                        .and_return(log_file)

      manifest_data = [{release: 'first', foo: 'bar'},{release: 'current', random: 'data'}]
      allow(manifest).to receive(:data)
                     .and_return(manifest_data)
      allow(log_file).to receive(:content)
                     .and_return ""

      expect( subject.current_release_data(remote) ).to eq release:'current',
                                                           random: 'data'
    end
  end

  describe "#rollback_release" do
    it "symlinks the previous release" do
      config   = double("Statistrano::Config", default_remote_config_responses )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = instance_double("Statistrano::Deployment::Manifest")
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                             .with( '/var/www/proj', remote )
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
      allow( remote ).to receive(:run)
      allow(remote).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("",'',true) )
      allow( manifest ).to receive(:remove_if)
      allow( manifest ).to receive(:save!)

      expect( subject ).to receive(:symlink_release)
                       .with( remote, release_two )

      subject.rollback_release remote
    end

    it "removes the newest release from disk on remote" do
      config   = double("Statistrano::Config", default_remote_config_responses )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = instance_double("Statistrano::Deployment::Manifest")
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                             .with( '/var/www/proj', remote )
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
                      .with( remote, release_two )
      allow( manifest ).to receive(:remove_if)
      allow( manifest ).to receive(:save!)

      allow(remote).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("",'',true) )
      expect( remote ).to receive(:run)
                      .with("rm -rf /var/www/proj/releases/#{release_three}")

      subject.rollback_release remote
    end

    it "removes the newest release from the manifest" do
      config   = double("Statistrano::Config", default_remote_config_responses )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = Statistrano::Deployment::Manifest.new '/var/www/proj', remote
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                             .with( '/var/www/proj', remote )
                                                             .and_return(manifest)


      release_one   = ( Time.now.to_i + 0 ).to_s
      release_two   = ( Time.now.to_i + 1 ).to_s
      release_three = ( Time.now.to_i + 2 ).to_s
      releases      = [release_three,release_two,release_one]
      allow( remote ).to receive(:run)
      allow(remote).to receive(:run)
                   .with("readlink /var/www/proj/current")
                   .and_return( HereOrThere::Response.new("",'',true) )


      # this is gnarly but we need to test against
      # the manifest release data because of the block in
      # Manifest#remove_if
      allow(remote).to receive(:run)
                   .with("cat /var/www/proj/manifest.json")
                   .and_return( HereOrThere::Response.new("[#{ releases.map{ |r| "{\"release\": \"#{r}\"}" }.join(',') }]",'',true) )

      allow( subject ).to receive(:symlink_release)
                       .with( remote, release_two )

      expect( manifest ).to receive(:save!)
      subject.rollback_release remote
      expect( manifest.data ).to eq releases[1..-1].map {|r| {release: r}}
    end

    it "errors if there is only one release" do
      config   = double("Statistrano::Config", default_remote_config_responses )
      remote   = instance_double("Statistrano::Remote", config: config )
      subject  = described_class.new
      manifest = instance_double("Statistrano::Deployment::Manifest")
      allow( Statistrano::Deployment::Manifest ).to receive(:new)
                                                             .and_return(manifest)

      release_one   = ( Time.now.to_i + 0 ).to_s
      allow( manifest ).to receive(:data)
                       .and_return([
                          { release: release_one }
                        ])

      expect( Statistrano::Log ).to receive(:error)
      subject.rollback_release remote
    end
  end

end
