module Statistrano
  module Deployment

    class Releases < Base

      class Config < Base::Config
        attr_accessor :release_count
        attr_accessor :release_dir
        attr_accessor :public_dir

        def initialize
          yield(self) if block_given?
        end
      end

      def initialize name
        super name
        @config = Config.new do |c|
          c.release_count = 5
          c.release_dir = "releases"
          c.public_dir = "current"
        end
      end

      def deploy
        super
        prune_releases
      end

      # Rollback to the previous release
      # @return [Void]
      def rollback_release
        releases = get_releases

        if releases.length > 1
          current_release = releases[0]
          past_release = releases[1]

          symlink_release( past_release )
          remove_release( current_release )

        else
          LOG.error "Whoa there, there's only one release -- you definetly shouldn't remove it"
        end
      end

      # Remove old releases
      # @return [Void]
      def prune_releases
        releases = get_releases
        if releases && releases.length > @config.release_count
          releases[@config.release_count..-1].each do |release|
            remove_release(release)
          end
        else
          LOG.msg "No releases to prune", nil
        end
      end

      # Return array of releases on the remote
      # @return [Array]
      def get_releases
        releases = []
        run_ssh_command("ls -m #{release_dir_path}") do |ch, stream, data|
          releases = data.strip.split
        end
        return releases
      end

      private

        # send code to remote server
        # @return [Void]
        def create_release
          current_release = release_name

          setup_release_dir_path( release_path(current_release) )
          rsync_to_remote( release_path(current_release) )
          symlink_release( current_release )

          # TODO: add_manifest

          LOG.msg "Created release at #{public_dir}"
        end

        # remove a release
        # @param name [String]
        # @return [Void]
        def remove_release name
          LOG.msg "Removing release '#{release}'"
          run_ssh_command "rm -rf #{release_dir_path}/#{name}"
        end

        # Symlink a release to the public path
        # @param name [String]
        # @return [Void]
        def symlink_release name
          "ln -nfs #{release_path(name)} #{public_path}"
        end

        # Return a release name based on current time
        # @return [String]
        def release_name
          Time.now.strftime("%Y%m%d%H%M%S")
        end

        # Full public_path
        # @return [String]
        def public_path
          File.join( @config.remote_dir, @config.public_dir )
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
          File.join( @config.remote_dir, @config.release_dir )
        end

    end

  end
end