require_relative 'manifest/release'
require_relative 'manifest/remote_store'

module Statistrano
  module Deployment

    #
    # Manifest keeps track of the state of releases for a deployment
    # and handles updating the manifest file on the remote
    #
    class Manifest

      attr_reader :config, :releases, :remote_store

      def initialize config, remote
        @config = config
        @remote_store = RemoteStore.new( @config, remote )
        @releases     = @remote_store.fetch.sort_by { |release| release.time }
      end

      def releases_desc
        releases.reverse
      end

      # array of release names
      # @return [Array]
      def list
        releases_desc.map do |release|
          release.name
        end
      end

      # add a release to the manifest
      # @param release [Release]
      # @return [Void]
      def add_release new_release

        # remove releases with the same name
        releases.keep_if do |existing_release|
          existing_release.name != new_release.name
        end

        releases << new_release
        update!
      end

      # remove a release to the manifest
      # @param name [String]
      # @return [Void]
      def remove_release name
        releases.keep_if do |existing_release|
          existing_release.name != name
        end
        update!
      end

      # update the manifest on the server
      # @return [Void]
      def update!
        remote_store.update_content releases_as_json
      end

      private

        # json array of the releases
        # @return [String]
        def releases_as_json
          "[" << releases_desc.map { |release| release.to_json }.join(",") << "]"
        end
    end

  end
end