
module Statistrano
  module Deployment

    class Branches < Base

      class Config < Base::Config
        attr_accessor :public_dir
        attr_accessor :manifest

        def initialize
          yield(self) if block_given?
        end
      end

      def initialize name
        @name = name
        @config = Config.new do |c|
          c.public_dir = Git.current_branch.to_slug
        end
        RakeTasks.register(self)
      end

      def after_configuration
        super
        @manifest = Manifest.new( @config )
      end

      private

        # send code to remote server
        # @return [Void]
        def create_release
          setup_release_path(release_path)
          rsync_to_remote(release_path)

          @manifest.add_release( Manifest::Release.new( @config.public_dir ) )

          LOG.msg "Created release at #{@config.public_dir}"
        end

        # return array of releases from the manifest
        # @return [Array]
        def get_releases
          @manifest.list
        end

        # path to the current release
        # this is based on the git branch
        # @return [String]
        def release_path
          File.join( @config.remote_dir, @config.public_dir )
        end

    end

  end
end