module Statistrano
  module Deployment
    module Strategy

      #
      # Branches is for deployments that depend upon the
      # current git branch, eg. doing feature branch deployments
      #
      class Branches < Base
        register_strategy :branches

        option :base_domain
        option :public_dir, :call, Proc.new { Asgit.current_branch.to_slug }
        option :post_deploy_task,  Proc.new { |d|
          d.push_current_release_to_manifest
          d.generate_index
        }

        validate :public_dir, lambda { |d| !d.to_s.empty? && d != '/' },
                 "'public_dir' can't be an empty string or '/'"

        task :list,           :list_releases,  "List branches"
        task :prune,          :prune_releases, "Prune a branch"
        task :generate_index, :generate_index, "Generate a branch index"
        task :open,           :open_url,       "Open the current branch URL"


        # output a list of the releases in manifest
        # @return [Void]
        def list_releases
          remotes.each do |remote|
            releases_data = sorted_release_data(remote)
            releases_data.map! do |release|
              "#{release[:name]} created at #{Time.at(release[:time]).strftime('%a %b %d, %Y at %l:%M %P')}"
            end
            Log.info remote.config.hostname.to_sym, *releases_data
          end
        end

        # trim releases not in the manifest,
        # get user input for removal of other releases
        # @return [Void]
        def prune_releases
          candidate_releases = []
          remotes.each do |remote|
            prune_untracked_releases(remote)
            candidate_releases.push *get_releases(remote)
            candidate_releases.uniq!
          end

          if candidate_releases.length > 0
            pick_and_remove_release candidate_releases
          else
            Log.warn "no releases to prune"
          end
        end

        # generate an index file for releases in the manifest
        # @return [Void]
        def generate_index
          remotes.each do |remote|
            index_dir  = File.join( remote.config.remote_dir, "index" )
            index_path = File.join( index_dir, "index.html" )
            remote.create_remote_dir index_dir
            remote.run "touch #{index_path} && echo '#{release_list_html(remote)}' > #{index_path}"
          end
        end

        # push the current release into the manifest
        # @return [Void]
        def push_current_release_to_manifest
          remotes.each do |remote|
            mnfst = manifest(remote)
            mnfst.put Release.new( config.public_dir, config ).to_hash, :name
            mnfst.save!
          end
        end

        private

          def manifest remote
            @_manifests ||= {}

            @_manifests.fetch( remote ) do
              @_manifests[remote] = Deployment::Manifest.new remote.config.remote_dir, remote
            end
          end

          def pick_and_remove_release candidate_releases
            picked_release = pick_release_to_remove candidate_releases
            if picked_release
              remotes.each do |remote|
                if get_releases(remote).include? picked_release
                  remove_release(remote, picked_release)
                end
              end
              generate_index
            else
              Log.warn "sorry, that isn't one of the releases"
            end
          end

          def pick_release_to_remove candidate_releases
            list_releases_with_index candidate_releases

            picked_release = Shell.get_input("select a release to remove: ").gsub(/[^0-9]/, '')

            if !picked_release.empty? && picked_release.to_i < candidate_releases.length
              return candidate_releases[picked_release.to_i]
            else
              return false
            end
          end

          def list_releases_with_index releases
            releases.each_with_index do |release,idx|
              Log.info :"[#{idx}]", "#{release}"
            end
          end

          # removes releases that are on the remote but not in the manifest
          # @return [Void]
          def prune_untracked_releases remote
            get_actual_releases(remote).each do |release|
              remove_release(remote, release) unless get_releases(remote).include? release
            end
          end

          def release_list_html remote
            releases = sorted_release_data(remote).map do |r|
              name = r.fetch(:name)
              r.merge({ repo_url: config.repo_url }) if config.repo_url
              Release.new( name, config, r )
            end

            Index.new( releases ).to_html
          end

          def sorted_release_data remote
            manifest(remote).data.sort_by do |r|
              r[:time]
            end.reverse
          end

          # remove a release
          # @param name [String]
          # @return [Void]
          def remove_release remote, name
            Log.info remote.config.hostname.to_sym, "Removing release '#{name}'"
            remote.run "rm -rf #{release_path(name, remote)}"
            manifest(remote).remove_if do |r|
              r[:name] == name
            end
            manifest(remote).save!
          end

          # return array of releases from the manifest
          # @return [Array]
          def get_releases remote
           sorted_release_data(remote).map { |r| r[:name] }
          end

          # return array of releases on the remote
          # @return [Array]
          def get_actual_releases remote
            remote.run("ls -mp #{remote.config.remote_dir}")
                  .stdout.strip.split(',')
                  .keep_if { |release| /\/$/.match(release) }
                  .map     { |release| release.strip.sub(/(\/$)/, '') }
                  .keep_if { |release| release != "index" }
          end

          # path to the current release
          # this is based on the git branch
          # @return [String]
          def current_release_path
            File.join( config.remote_dir, config.public_dir )
          end

          # path to a specific release
          # @return [String]
          def release_path name, remote
            File.join( remote.config.remote_dir, name )
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
end

require_relative 'branches/index'
require_relative 'branches/release'
