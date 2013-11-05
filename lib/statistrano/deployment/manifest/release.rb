module Statistrano
  module Deployment
    class Manifest

      #
      # Manages the state of a single release for the manifest
      #
      class Release

        attr_reader :name, :config, :options

        # init a release
        # @param name [String] name of the release
        # @param config [Obj] the config object
        # @param options [Hash] :time, :commit, & :link || :repo_url
        def initialize name, config, options={}
          @name    = name
          @config  = config
          @options = symbolize_keys options
        end

        def time
          @_time ||= options.fetch(:time) { Time.now.to_i }
        end

        def commit
          @_commit ||= options.fetch(:commit) { Asgit.current_commit }
        end

        def link
          @_link ||= options.fetch(:link) { (options[:repo_url]) ? "#{options[:repo_url]}/tree/#{commit}" : nil }
        end

        def log_info
          LOG.msg "#{name} created at #{Time.at(time).strftime('%a %b %d, %Y at %l:%M %P')}"
        end

        # convert the release to an li element
        # @return [String]
        def as_li
          "<li>" +
          "<a href=\"http://#{name}.#{config.base_domain}\">#{name}</a>" +
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

          def symbolize_keys hash
            hash.inject({}) do |opts,(k,v)|
              opts[k.to_sym] = v
              opts
            end
          end
      end

    end
  end
end