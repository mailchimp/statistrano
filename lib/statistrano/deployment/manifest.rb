module Statistrano
  module Deployment

    class Manifest

      attr_reader :releases

      def initialize config
        @releases = []
        @config = config
        @ssh = SSH.new( @config )
        @path = @config.remote_dir
      end

      # create a manifest for the first time
      # @param first_release [Release]
      # @return [Void]
      def create first_release
        cmd = 'touch #{manifest_path}'
        @ssh.run_command(cmd)

        manifest = "[#{first_release.to_json}]"
        cmd = "echo '#{manifest}' > #{manifest_path}"
        @ssh.run_command(cmd)
      end

      # add a release to the manifest
      # @param release [Release]
      # @return [Void]
      def add_release release
        manifest = get
        manifest << release
        cmd = "echo '#{manifest}' > #{manifest_path}"
        @ssh.run_command(cmd)
      end

      # remove a release to the manifest
      # @param name [String]
      # @return [Void]
      def remove_release name
      end

      # get the manifest for this deployment
      # @return [Array]
      def get
        cmd = 'tail -n 1000 #{manifest_path}'
        @ssh.run_command(cmd) do |ch, stream, data|
          manifest = JSON.parse(data).sort_by { |r| r["time"] }.reverse
        end
        return manifest
      end

      class Release

        attr_reader :name
        attr_reader :time
        attr_reader :commit
        attr_reader :link

        def initialize name, time=nil, commit=nil, repo_url=nil
          @name = name
          @time ||= Time.now.to_i
          @commit ||= Git.current_commit
          @link = repo_url ? repo_url + '/tree/' + @commit : nil
        end

        def to_json
          hash = {
            name: @name,
            time: @time,
            commit: @commit
          }

          if @link
            hash.merge({
              link: @link
            })
          end

          return hash.to_json
        end
      end

      private

        def manifest_path
          File.join( @path, 'manifest.json' )
        end

    end

  end
end