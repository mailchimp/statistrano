module Statistrano
  module Deployment

    #
    # Branches is for deployments that depend upon the
    # current git branch, eg. doing feature branch deployments
    #
    class Branches < Base
      register_type :branches

      options :public_dir, :post_deploy_task, :base_domain

      task :list, :list_releases, "List branches"
      task :prune, :prune_releases, "Prune a branch"
      task :generate_index, :generate_index, "Generate a branch index"
      task :open, :open_url, "Open the current branch URL"

      def initialize name
        super name

        # these are set on initialization due to
        # requiring access to instance information
        #
        config.public_dir = Asgit.current_branch.to_slug
        config.post_deploy_task = "#{@name}:generate_index"
      end

      # output a list of the releases in manifest
      # @return [Void]
      def list_releases
        manifest.releases_desc.each { |release| release.log_info }
      end

      # trim releases not in the manifest,
      # get user input for removal of other releases
      # @return [Void]
      def prune_releases
        prune_untracked_releases

        if get_releases && get_releases.length > 0
          pick_and_remove_release
        else
          Log.warn "no releases to prune"
        end
      end

      # generate an index file for releases in the manifest
      # @return [Void]
      def generate_index
        index_dir  = File.join( config.remote_dir, "index" )
        index_path = File.join( index_dir, "index.html" )
        setup_release_path( index_dir )
        remote.run "touch #{index_path} && echo '#{release_list_html}' > #{index_path}"
      end

      private

        def manifest
          @_manifest ||= Manifest.new( config )
        end

        def pick_and_remove_release
          picked_release = pick_release_to_remove
          if picked_release
            remove_release(picked_release)
            generate_index
          else
            Log.warn "sorry, that isn't one of the releases"
          end
        end

        def pick_release_to_remove
          list_releases_with_index

          picked_release = Shell.get_input("select a release to remove: ").gsub(/[^0-9]/, '')

          if !picked_release.empty? && picked_release.to_i < get_releases.length
            return get_releases[picked_release.to_i]
          else
            return false
          end
        end

        def list_releases_with_index
          get_releases.each_with_index do |release,idx|
            Log.info :"[#{idx}]", "#{release}"
          end
        end

        # removes releases that are on the remote but not in the manifest
        # @return [Void]
        def prune_untracked_releases
          get_actual_releases.each do |release|
            remove_release(release) unless get_releases.include? release
          end
        end

        def release_list_html
          release_list = manifest.releases_desc.map { |release| release.as_li }.join('')
          template = IO.read( File.expand_path( '../../../../templates/index.html', __FILE__) )
          template.gsub( '{{release_list}}', release_list )
        end

        # send code to remote server
        # @return [Void]
        def create_release
          setup_release_path(current_release_path)
          rsync_to_remote(current_release_path)

          manifest.add_release( Manifest::Release.new( config.public_dir, config ) )

          Log.info "Created release at #{config.public_dir}"
        end

        # remove a release
        # @param name [String]
        # @return [Void]
        def remove_release name
          Log.info "Removing release '#{name}'"
          remote.run "rm -rf #{release_path(name)}"
          manifest.remove_release(name)
        end

        # return array of releases from the manifest
        # @return [Array]
        def get_releases
          manifest.list
        end

        # return array of releases on the remote
        # @return [Array]
        def get_actual_releases
          releases = []
          resp = remote.run("ls -mp #{config.remote_dir}")
          releases = resp.stdout.strip.split(',')
          releases.keep_if { |release| /\/$/.match(release) }
          releases.map { |release| release.strip.gsub(/(\/$)/, '') }.keep_if { |release| release != "index" }
        end

        # path to the current release
        # this is based on the git branch
        # @return [String]
        def current_release_path
          File.join( config.remote_dir, config.public_dir )
        end

        # path to a specific release
        # @return [String]
        def release_path name
          File.join( config.remote_dir, name )
        end

        # open the current checked out branch
        # @return [Void]
        def open_url
          if config.base_domain
            url = "http://#{config.public_dir}.#{config.base_domain}"
            system "open #{url}"
          end
        end

    end

  end
end