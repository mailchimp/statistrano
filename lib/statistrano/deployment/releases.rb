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
        @config = Config.new do |c|
          c.release_count = 5
          c.release_dir = "releases"
          c.public_dir = "current"
        end
        RakeTasks.register(self)
      end


      # define certain things that an action
      # depends on
      # @return [Void]
      def prepare_for_action
        super
        @manifest = Manifest.new( @config, @ssh )
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
        pruned = false

        if releases && releases.length > @config.release_count
          releases[@config.release_count..-1].each do |release|
            remove_release(release)
            pruned = true
          end
        end

        get_actual_releases.each do |r|

          unless releases.include? r
            remove_release(r)
          end

        end

        unless pruned
          LOG.msg "No releases to prune", nil
        end
      end

      # Output a list of releases & their date
      # @return [Void]
      def list_releases
        releases = get_releases
        releases.each_with_index do |release, idx|
          current = ( idx == 0 ) ? "current" : nil
          LOG.msg Time.at(release.to_i).strftime('%a %b %d, %Y at %l:%M %P'), current, :blue
        end
      end

      private

        # Return array of releases from manifest
        # @return [Array]
        def get_releases
          @manifest.list
        end

        # Return array of releases on the remote
        # @return [Array]
        def get_actual_releases
          releases = []
          @ssh.run_command("ls -m #{release_dir_path}") do |ch, stream, data|
            releases = data.strip.split(',').map { |r| r.strip }.reverse
          end
          return releases
        end

        # send code to remote server
        # @return [Void]
        def create_release
          current_release = release_name

          setup_release_path( release_path(current_release) )
          rsync_to_remote( release_path(current_release) )
          symlink_release( current_release )

          @manifest.add_release( Manifest::Release.new( current_release ))

          LOG.msg "Created release at #{public_path}"
        end

        # create the release dir on the remote by copying the current release
        # @param release_path [String] path of release on remote
        # @return [Void]
        def setup_release_path release_path
          previous_release = get_releases[0] # the current release is the previous in this case

          if previous_release
            LOG.msg "Setting up the remote"
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