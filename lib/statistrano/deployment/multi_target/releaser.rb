module Statistrano
  module Deployment
    class MultiTarget

      class Releaser
        extend ::Statistrano::Config::Configurable

        options :remote_dir, :local_dir

        option :release_count, 5
        option :release_dir, "releases"
        option :public_dir,  "current"

        attr_reader :release_name

        def initialize options={}
          config.options.each do |opt,val|
            config.send opt, options.fetch(opt,val)
          end

          check_required_options :remote_dir, :local_dir
          @release_name = Time.now.to_i.to_s
        end

        def create_release target, build_data={}
          setup_release_path      target
          rsync_to_remote         target
          symlink_release         target
          add_release_to_manifest target, build_data
          prune_releases          target
        end

        def setup_release_path target
          target.create_remote_dir release_path(target)
        end

        def rsync_to_remote target
          target.rsync_to_remote local_path(target), release_path(target)
        end

        def symlink_release target, release=nil
          target.run "ln -nfs #{release_path(target, release)} #{public_path(target)}"
        end

        def prune_releases target
          remove_untracked_releases target
          remove_releases_beyond_release_count target
        end

        def list_releases target
          manifest = new_manifest target
          manifest.data.keep_if do |rel|
            rel.has_key?(:release)
          end.sort_by do |rel|
            rel[:release]
          end.reverse
        end

        def rollback_release target
          manifest = new_manifest target
          releases = tracked_releases target, manifest

          unless releases.length > 1
            return Log.error "There is only on release, best not to remove it"
          end

          symlink_release target, releases[1]
          remove_release releases[0], target, manifest
          manifest.save!
        end

        def add_release_to_manifest target, build_data={}
          manifest = new_manifest target
          manifest.push build_data.merge(release: release_name)
          manifest.save!
        end

        private

          def new_manifest target
            Manifest.new target_overridable_config(:remote_dir, target), target
          end

          def target_overridable_config option, target
            (target && target.config.public_send(option)) || config.public_send(option)
          end

          def remove_releases_beyond_release_count target
            manifest = new_manifest target
            beyond   = tracked_releases(target, manifest)[target_overridable_config(:release_count, target)..-1]
            Array(beyond).each do |beyond|
              remove_release beyond, target, manifest
            end
            manifest.save!
          end

          def remove_release release_name, target, manifest
            manifest.remove_if { |r| r[:release] == release_name }
            target.run("rm -rf #{File.join(releases_path(target), release_name)}")
          end

          def remove_untracked_releases target
            (remote_releases(target) - tracked_releases(target)).each do |untracked|
              target.run("rm -rf #{File.join(releases_path(target), untracked)}")
            end
          end

          def remote_releases target
            target.run("ls -m #{releases_path(target)}").stdout
                  .split(',').map(&:strip)
          end

          def tracked_releases target, manifest=nil
            manifest ||= new_manifest target
            manifest.data.map do |data|
              data.fetch(:release, nil)
            end.compact.sort.reverse
          end

          def check_required_options *opts
            opts.each do |opt|
              raise ArgumentError, "a #{opt} is required" unless config.public_send(opt)
            end
          end

          def local_path target=nil
            File.join( Dir.pwd, target_overridable_config(:local_dir, target) )
          end

          def releases_path target=nil
            File.join( target_overridable_config(:remote_dir, target), target_overridable_config(:release_dir, target) )
          end

          def release_path target=nil, release=nil
            release ||= release_name
            File.join( releases_path(target), release )
          end

          def public_path target=nil
            File.join( target_overridable_config(:remote_dir, target), target_overridable_config(:public_dir, target) )
          end

      end

    end
  end
end