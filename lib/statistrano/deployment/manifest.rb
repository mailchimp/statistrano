module Statistrano
  module Deployment

    #
    # Manifest keeps track of the state of releases for a deployment
    # and handles updating the manifest file on the remote
    #
    class Manifest

      def initialize config, ssh_session
        @config = config
        @ssh = ssh_session
        @remote_store = RemoteStore.new(@config, @ssh)
        @releases = @remote_store.fetch
      end

      def releases
        @releases.sort_by { |release| release.time }.reverse
      end

      # array of release names
      # @return [Array]
      def list
        releases.map do |release|
          release.name
        end
      end

      # add a release to the manifest
      # @param release [Release]
      # @return [Void]
      def add_release new_release

        # remove releases with the same name
        @releases.keep_if do |existing_release|
          existing_release.name != new_release.name
        end

        @releases << new_release
        update!
      end

      # remove a release to the manifest
      # @param name [String]
      # @return [Void]
      def remove_release name
        @releases.keep_if do |existing_release|
          existing_release.name != name
        end
        update!
      end

      # update the manifest on the server
      # @return [Void]
      def update!
        @remote_store.update_content releases_as_json
      end

      #
      # Manages the state of a single release for the manifest
      #
      class Release

        attr_reader :name

        # init a release
        # @param name [String] name of the release
        # @param config [Obj] the config object
        # @param options [Hash] :time, :commit, & :link || :repo_url
        def initialize name, config, options={}
          @name = name
          @config = config
          @options = convert_string_keys_to_symbols(options)
        end

        def time
          @time ||= @options.fetch(:time) { Time.now.to_i }
        end

        def commit
          @commit ||= @options.fetch(:commit) { Git.current_commit }
        end

        def link
          @link ||= @options.fetch(:link) { (@options[:repo_url]) ? "#{@options[:repo_url]}/tree/#{commit}" : nil }
        end

        def log_info
          LOG.msg "#{name} created at #{Time.at(time).strftime('%a %b %d, %Y at %l:%M %P')}"
        end

        # convert the release to an li element
        # @return [String]
        def as_li
          "<li>" +
          "<a href=\"http://#{name}.#{@config.base_domain}\">#{name}</a>" +
          "<small>updated: #{Time.at(time).strftime('%A %b %d, %Y at %l:%M %P')}</small>" +
          "</li>"
        end

        # convert the release to a json object
        # @return [String]
        def to_json
          hash = {
            name: name,
            time: time,
            commit: commit
          }
          hash.merge({ link: link }) if link

          return hash.to_json
        end

        private

          def convert_string_keys_to_symbols hash
            hash.inject({}) do |opts,(k,v)|
              opts[k.to_sym] = v
              opts
            end
          end
      end

      private

        # json array of the releases
        # @return [String]
        def releases_as_json
          "[" << @releases.map { |release| release.to_json }.join(",") << "]"
        end

        # manages the manifest file on the remote
        #
        class RemoteStore

          def initialize config, ssh
            @config = config
            @ssh = ssh
            @path = @config.remote_dir
          end

          def fetch
            fetch_remote_manifest.map { |release| new_release_instance( release ) }
          end

          def update_content string
            cmd = "touch #{manifest_path} && echo '#{string}' > #{manifest_path}"
            @ssh.run_command(cmd)
          end

          private

            # path to the manifest
            # @return [String]
            def manifest_path
              File.join( @path, 'manifest.json' )
            end

            def fetch_remote_manifest
              raw_manifest = @ssh.run_command("touch #{manifest_path} && cat #{manifest_path}")
              return (raw_manifest) ? JSON.parse( raw_manifest ) : []
            end

            def new_release_instance release
              name = release.delete("name")
              release.merge({ repo_url: @config.repo_url }) if @config.repo_url
              return Release.new( name, @config, release )
            end
        end
    end

  end
end