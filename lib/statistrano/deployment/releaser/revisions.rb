module Statistrano
  module Deployment
    module Releaser

      class Revisions
        include Strategy::InvokeTasks

        attr_reader :release_name

        def initialize
          @release_name = Time.now.to_i.to_s
        end

        def create_release remote, build_data={}
          setup_release_path      remote
          rsync_to_remote         remote
          invoke_pre_symlink_task remote
          symlink_release         remote
          add_release_to_manifest remote, build_data
          prune_releases          remote
        end

        def setup_release_path remote
          current_release = current_release remote
          remote.create_remote_dir releases_path(remote)

          if current_release.empty?
            remote.create_remote_dir release_path(remote)
          else
            remote.run "cp -a #{release_path(remote, current_release)} #{release_path(remote)}"
          end
        end

        def rsync_to_remote remote
          resp = remote.rsync_to_remote local_path(remote), release_path(remote)
          unless resp.success?
            abort()
          end
        end

        def symlink_release remote, release=nil
          remote.run "ln -nfs #{release_path(remote, release)} #{public_path(remote)}"
        end

        def prune_releases remote
          remove_untracked_releases remote
          remove_releases_beyond_release_count remote
        end

        def list_releases remote
          manifest = new_manifest remote
          manifest.data.keep_if do |rel|
            rel.has_key?(:release)
          end.sort_by do |rel|
            rel[:release]
          end.reverse
        end

        # merge of manifest & log data (if a log)
        def current_release_data remote
          release_data = new_manifest(remote).data.last

          if remote.config.log_file_path
            release_data.merge! log_file(remote).last_entry 
          end

          release_data
        end

        def rollback_release remote
          manifest = new_manifest remote
          releases = tracked_releases remote, manifest

          unless releases.length > 1
            return Log.error "There is only one release, best not to remove it"
          end

          symlink_release remote, releases[1]
          remove_release releases[0], remote, manifest
          manifest.save!
        end

        def add_release_to_manifest remote, build_data={}
          manifest = new_manifest remote
          manifest.push build_data.merge(release: release_name)
          manifest.save!
        end

        private

          def new_manifest remote
            Deployment::Manifest.new remote.config.remote_dir, remote
          end

          def log_file remote
            Deployment::LogFile.new remote.config.log_file_path, remote
          end

          def remove_releases_beyond_release_count remote
            manifest = new_manifest remote
            beyond   = tracked_releases(remote, manifest)[remote.config.release_count..-1]
            Array(beyond).each do |beyond|
              remove_release beyond, remote, manifest
            end
            manifest.save!
          end

          def remove_release release_name, remote, manifest
            if release_name == current_release(remote)
              Log.warn "did not remove release '#{release_name}' because it is current"
              return
            end

            manifest.remove_if { |r| r[:release] == release_name }
            remote.run("rm -rf #{File.join(releases_path(remote), release_name)}")
          end

          def remove_untracked_releases remote
            manifest = new_manifest remote
            (remote_releases(remote) - tracked_releases(remote)).each do |untracked_release|
              remove_release untracked_release, remote, manifest
            end
          end

          def current_release remote
            resp = remote.run("readlink #{public_path(remote)}")
            resp.stdout.sub( /#{releases_path(remote)}\/?/, '' ).strip
          end

          def remote_releases remote
            remote.run("ls -m #{releases_path(remote)}").stdout
                  .split(',').map(&:strip)
          end

          def tracked_releases remote, manifest=nil
            manifest ||= new_manifest remote
            manifest.data.map do |data|
              data.fetch(:release, nil)
            end.compact.sort.reverse
          end

          def local_path remote=nil
            File.join( Dir.pwd, remote.config.local_dir )
          end

          def releases_path remote=nil
            File.join( remote.config.remote_dir, remote.config.release_dir )
          end

          def release_path remote=nil, release=nil
            release ||= release_name
            File.join( releases_path(remote), release )
          end

          def public_path remote=nil
            File.join( remote.config.remote_dir, remote.config.public_dir )
          end

      end

    end
  end
end
