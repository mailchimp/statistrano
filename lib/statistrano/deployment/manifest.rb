module Statistrano
  module Deployment

    class Manifest

      attr_reader :releases

      def initialize config, ssh_session
        @config = config
        @ssh = ssh_session
        @path = @config.remote_dir
        @releases = get.sort_by { |r| r.time }.reverse
      end

      # array of release names
      # @return [Array]
      def list
        get.map do |r|
          r.name
        end
      end

      # add a release to the manifest
      # @param release [Release]
      # @return [Void]
      def add_release release

        # remove releases with the same name
        @releases.keep_if do |r|
          r.name != release.name
        end

        @releases << release
        update
      end

      # remove a release to the manifest
      # @param name [String]
      # @return [Void]
      def remove_release name
        @releases.keep_if do |r|
          r.name != name
        end
        update
      end

      # update the manifest on the server
      # @return [Void]
      def update
        cmd = "touch #{manifest_path} && echo '#{releases_as_json}' > #{manifest_path}"
        @ssh.run_command(cmd)
      end

      class Release

        attr_reader :name
        attr_reader :time
        attr_reader :commit
        attr_reader :link

        # init a release
        # @param name [String] name of the release
        # @param hash [Hash] :time, :commit, & :link || :repo_url
        def initialize name, hash={}
          @name = name
          @time = (hash[:time]) ? hash[:time] : Time.now.to_i
          @commit = (hash[:commit]) ? hash[:commit] : Git.current_commit
          @link = (hash[:link]) ? hash[:link] : (hash[:repo_url]) ? hash[:repo_url] + '/tree/' + @commit : nil
        end

        # convert the release to a json object
        # @return [String]
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

        # get the manifest for this deployment
        # @return [Array]
        def get
          cmd = "touch #{manifest_path} && tail -n 1000 #{manifest_path}"
          manifest = []
          @ssh.run_command(cmd) do |ch, stream, data|
            manifest = JSON.parse(data).sort_by { |r| r["time"] }.reverse
          end
          releases = []
          if manifest.length > 0
            manifest.each do |r|

              options = {
                time: r["time"],
                commit: r["commit"]
              }

              if r["link"]
                options.merge({ link: r["link"] })
              elsif @config.repo_url
                options.merge({ repo_url: @config.repo_url })
              end

              releases << Release.new( r["name"], options )
            end
          end
          return releases
        end

        # path to the manifest
        # @return [String]
        def manifest_path
          File.join( @path, 'manifest.json' )
        end

        # json array of the releases
        # @return [String]
        def releases_as_json
          output = "["
          @releases.each_with_index do |r,idx|
            output << r.to_json
            unless idx == (@releases.length-1)
              output << ','
            end
          end
          output << "]"
        end
    end

  end
end