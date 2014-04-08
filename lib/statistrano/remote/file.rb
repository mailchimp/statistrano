module Statistrano
  class Remote

    class File

      attr_reader :path, :remote, :permissions

      def initialize path, remote, permissions=644
        @path   = path
        @remote = remote
        @permissions = permissions
      end

      def content
        resp = remote.run "cat #{path}"
        if resp.success?
          resp.stdout
        else
          ""
        end
      end

      def update_content! new_content
        create_remote_file unless remote_file_exists?
        resp = remote.run "echo '#{new_content}' > #{path}"

        if resp.success?
          Log.info :success, "file at #{path} on #{remote.config.hostname} saved"
        else
          Log.error "problem saving the file #{path} on #{remote.config.hostname}",
                    resp.stderr
        end
      end

      def destroy!
        resp = remote.run "rm #{path}"
        if resp.success?
          Log.info :success, "file at #{path} on #{remote.config.hostname} removed"
        else
          Log.error "failed to remove #{path} on #{remote.config.hostname}",
                    resp.stderr
        end
      end

      private

        def remote_file_exists?
          resp = remote.run "[ -f #{path} ] && echo \"exists\""
          resp.success? && resp.stdout.strip == "exists"
        end

        def create_remote_file
          resp = remote.run "touch #{path} " +
                            "&& chmod #{permissions} #{path}"

          if resp.success?
            Log.info :success, "created manifest file on #{remote.config.hostname}"
          else
            Log.error "problem saving the manifest for #{remote.config.hostname}",
                      resp.stderr
          end
        end

    end

  end
end