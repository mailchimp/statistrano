module Statistrano
  class Base

    # Each added server creates rake tasks namespaced with it's name
    #
    # Example's below assum that your server is named "foo"
    #
    # [+foo:deploy+] Builds, rsyncs, and creates as release on the remote
    # [+foo:releases:create+] Create and transfer a release to the remote, but dont build
    # [+foo:releases:list+] List releases on the remote
    # [+foo:releases:prune+] Remove old releases if over :release_count
    # [+foo:rollback+] Rollback release to previous
    module RakeTasks
      class << self

        # Add rake tasks
        include ::Rake::DSL

        # Register rake namespaces and tasks for registered servers
        # @return [Void]
        def register(server)
          # binding.pry
          # Define rake tasks
          namespace server.name.to_sym do

            desc "Deploy to #{server.name}"
            task :deploy do
              if server.git_check_branch
                server.safe_deploy
              else
                server.deploy
              end
            end

            desc "Rollback #{server.name} to last releases"
            task :rollback do
              server.rollback_release
            end

            desc "manage releases for #{server.name}"
            namespace :releases do
              desc "create a new release for #{server.name}"
              task :create do
                server.create_release
              end

              desc "prune releases to release count"
              task :prune do
                server.prune_releases
              end

              desc "list releases"
              task :list do
                server.get_releases
              end

              desc "browse releases"
              task :browse do
                server.browse_releases
              end
            end
            task :releases => ['releases:list']

            desc "group of generate tasks"
            namespace :generate do
              task :setup do
                index_dir = File.join( server.project_root, "index")
                server.run_ssh_command "mkdir #{index_dir}"
              end

              desc "generate a feature index page"
              task :index do
                releases = server.array_of_releases
                index_dir = File.join( server.project_root, "index")
                index_path = File.join( index_dir, "index.html")
                releases_string = ""
                releases.each do |release|
                  releases_string << "<li>"
                  releases_string << "<a href='http://"
                  releases_string << release["name"]
                  releases_string << "."
                  releases_string << server.base_domain
                  releases_string << "'>"
                  releases_string << release["name"]
                  releases_string << "</a></li>"
                end
                template = IO.read( File.expand_path( '../../../../templates/index.html', __FILE__) ).gsub( '{{release_list}}', releases_string )
                server.run_ssh_command "touch #{index_path}"
                server.run_ssh_command "echo '#{template}' > #{index_path}"
              end
            end
          end
        end
      end
    end

  end
end
