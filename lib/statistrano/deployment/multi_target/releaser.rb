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

        def setup_release_path target
          target.create_remote_dir release_path
        end

        def rsync_to_remote target
          target.rsync_to_remote local_path, release_path
        end

        def symlink_release target
          target.run "ln -nfs #{release_path} #{public_path}"
        end

        def prune_releases target
          remove_untracked_releases target
          remove_releases_beyond_release_count target
        end

        def add_release_to_manifest target, build_data={}
          manifest = Manifest.new config.remote_dir, target
          manifest.push build_data.merge(release: release_name)
          manifest.save!
        end

        private

          def remove_releases_beyond_release_count target
            manifest = Manifest.new config.remote_dir, target
            beyond   = tracked_releases(target, manifest)[config.release_count..-1]
            Array(beyond).each do |beyond|
              manifest.remove_if { |r| r[:release] == beyond }
              target.run("rm -rf #{File.join(releases_path, beyond)}")
            end
            manifest.save!
          end

          def remove_untracked_releases target
            (remote_releases(target) - tracked_releases(target)).each do |untracked|
              target.run("rm -rf #{File.join(releases_path, untracked)}")
            end
          end

          def remote_releases target
            target.run("ls -m #{releases_path}").stdout
                  .split(',').map(&:strip)
          end

          def tracked_releases target, manifest=nil
            manifest ||= Manifest.new config.remote_dir, target
            manifest.data.map do |data|
              data.fetch(:release, nil)
            end.compact
          end

          def check_required_options *opts
            opts.each do |opt|
              raise ArgumentError, "a #{opt} is required" unless config.public_send(opt)
            end
          end

          def local_path
            File.join( Dir.pwd, config.local_dir )
          end

          def releases_path
            File.join( config.remote_dir, config.release_dir )
          end

          def release_path
            File.join( releases_path, release_name )
          end

          def public_path
            File.join( config.remote_dir, config.public_dir )
          end

      end

    end
  end
end