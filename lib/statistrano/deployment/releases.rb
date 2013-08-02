module Statistrano
  module Deployment

    #
    # Releases handles deployments where you want the option
    # to rollback to previous deploys.
    #
    class Releases < Base

      #
      # Config holds all deployment configuration details
      #
      class Config < Base::Config
        config_attribute :release_count
        config_attribute :release_dir
        config_attribute :public_dir

        def initialize
          yield(self) if block_given?
        end

        def tasks
          super.merge({
            :rollback => { method: :rollback_release, desc: "Rollback to last release" },
            :prune => { method: :prune_releases, desc: "Prune releases to release count" },
            :list => { method: :list_releases, desc: "List releases" }
          })
        end
      end

      def initialize name
        @name = name
        configure do
          release_count 5
          release_dir   "releases"
          public_dir    "current"
        end
        RakeTasks.register(self)
      end

      def config
        @_config ||= Config.new
      end

      # prune releases after the deploy has run
      # @return [Void]
      def deploy
        super
        prune_releases
      end

      # Rollback to the previous release
      # @return [Void]
      def rollback_release
        releases = get_releases
        return LOG.error "Whoa there, there's only one release -- you definetly shouldn't remove it" unless releases.length > 1

        symlink_release( releases[1] ) # previous release
        remove_release( releases[0] ) # current release
      end

      # Remove old releases
      # @return [Void]
      def prune_releases
        remove_untracked_releases
        remove_releases_beyond_release_count
      end

      # Output a list of releases & their date
      # @return [Void]
      def list_releases
        get_releases.each_with_index do |release, idx|
          current = ( idx == 0 ) ? "current" : nil
          LOG.msg Time.at(release.to_i).strftime('%a %b %d, %Y at %l:%M %P'), current, :blue
        end
      end

      private

        def remove_releases_beyond_release_count
          if releases_beyond_release_count
            releases_beyond_release_count.each do |release|
              remove_release(release)
            end
          else
            LOG.msg( "No releases to prune", nil )
          end
        end

        def releases_beyond_release_count
          get_releases[config.release_count..-1]
        end

        def remove_untracked_releases
          tracked_releases = get_releases
          get_actual_releases.each do |release|
            remove_release(release) unless tracked_releases.include? release
          end
        end

        def setup
          super
          @manifest = Manifest.new( config, @ssh )
        end

        # Return array of releases from manifest
        # @return [Array]
        def get_releases
          setup
          @manifest.list
        end

        # Return array of releases on the remote
        # @return [Array]
        def get_actual_releases
          ActualReleases.new( @ssh, release_dir_path ).as_array
        end

        # service class to get actual releases
        class ActualReleases

          def initialize ssh, dir_path
            @ssh = ssh
            @dir_path = dir_path
          end

          def as_array
            ls_release_dir.strip.split(',').map { |release| release.strip }.reverse
          end

          private

            def ls_release_dir
              @ssh.run_command("ls -m #{@dir_path}") do |ch, stream, data|
                return data
              end
            end
        end

        # send code to remote server
        # @return [Void]
        def create_release
          current_release = release_name

          create_release_on_remote(current_release)
          add_release_to_manifest(current_release)

          LOG.msg "Created release at #{public_path}"
        end

        def add_release_to_manifest name
          @manifest.add_release( Manifest::Release.new( name, config ))
        end

        def create_release_on_remote name
          setup_release_path release_path(name)
          rsync_to_remote release_path(name)
          symlink_release name
        end

        # create the release dir on the remote by copying the current release
        # @param release_path [String] path of release on remote
        # @return [Void]
        def setup_release_path release_path
          previous_release = get_releases[0] # the current release is the previous in this case

          if previous_release && previous_release != release_name
            LOG.msg "Setting up the remote by copying previous release"
            @ssh.run_command "cp -a #{release_path(previous_release)} #{release_path}"
          else
            super
          end
        end

        # remove a release
        # @param name [String]
        # @return [Void]
        def remove_release name
          LOG.msg "Removing release '#{name}'"
          @ssh.run_command "rm -rf #{release_dir_path}/#{name}"

          @manifest.remove_release(name)
        end

        # Symlink a release to the public path
        # @param name [String]
        # @return [Void]
        def symlink_release name
          @ssh.run_command "ln -nfs #{release_path(name)} #{public_path}"
        end

        # Return a release name based on current time
        # @return [String]
        def release_name
          Time.now.to_i.to_s
        end

        # Full public_path
        # @return [String]
        def public_path
          File.join( config.remote_dir, config.public_dir )
        end

        # Full path to a release
        # @param name [String] name of the release
        # @return [String] full path to the release
        def release_path name
          File.join( release_dir_path, name )
        end

        # Full path to release directory
        # @return [String]
        def release_dir_path
          File.join( config.remote_dir, config.release_dir )
        end

    end

  end
end