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

      # Return array of releases on the remote
      # @return [Array]
      def list_releases
        releases = []
        run_ssh_command("ls -m #{release_path}") do |ch, stream, data|
          releases = data.strip.split
        end
        return releases
      end

      private

        # Full path to release directory
        # @return [String]
        def release_path
          File.join( @config.remote_dir, @config.release_dir )
        end

    end

  end
end