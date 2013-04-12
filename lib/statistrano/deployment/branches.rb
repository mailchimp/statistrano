require 'pry'
module Statistrano
  module Deployment

    class Branches < Base

      class Config < Base::Config
        attr_accessor :public_dir
        attr_accessor :manifest

        def initialize
          yield(self) if block_given?
        end

        def tasks
          super.merge({
            :list => :list_releases,
            :prune => :prune_releases
          })
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

      def list_releases
        @manifest.releases.each do |r|
          LOG.msg "#{r.name} created at #{Time.at(r.time).strftime('%a %b %d, %Y at %l:%M %P')}"
        end
      end

      def prune_releases
        releases = get_releases

        get_actual_releases.each do |r|
          remove_release(r) unless releases.include? r
        end

        if releases && releases.length > 0

          releases.each_with_index do |r,idx|
            LOG.msg "#{r}", "[#{idx}]", :blue
          end

          print "select a release to remove: "
          input = get_input.gsub(/[^0-9]/, '')
          release_to_remove = ( input != "" ) ? input.to_i : nil

          if (0..(releases.length-1)).to_a.include?(release_to_remove)
            remove_release( get_releases[release_to_remove] )
          else
            LOG.warn "sorry that isn't one of the releases"
          end

        else
          LOG.warn "no releases to prune"
        end
      end

      private

        # send code to remote server
        # @return [Void]
        def create_release
          setup_release_path(current_release_path)
          rsync_to_remote(current_release_path)

          @manifest.add_release( Manifest::Release.new( @config.public_dir ) )

          LOG.msg "Created release at #{@config.public_dir}"
        end

        # remove a release
        # @param name [String]
        # @return [Void]
        def remove_release name
          LOG.msg "Removing release '#{name}'"
          @ssh.run_command "rm -rf #{release_path(name)}"
          @manifest.remove_release(name)
        end

        # return array of releases from the manifest
        # @return [Array]
        def get_releases
          @manifest.list
        end

        # return array of releases on the remote
        # @return [Array]
        def get_actual_releases
          releases = []
          @ssh.run_command("ls -mp #{@config.remote_dir}") do |ch, stream, data|
            releases = data.strip.split(',')
          end
          releases.keep_if { |r| /\/$/.match(r) }
          releases.map { |r| r.strip.gsub(/(\/$)/, '') }.keep_if { |r| r != "index" }
        end

        # path to the current release
        # this is based on the git branch
        # @return [String]
        def current_release_path
          File.join( @config.remote_dir, @config.public_dir )
        end

        # path to a specific release
        # @return [String]
        def release_path name
          File.join( @config.remote_dir, name )
        end

        def get_input
          STDIN.gets.chomp
        end

    end

  end
end