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

      def update
      end

      def create
      end

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
    end

  end
end