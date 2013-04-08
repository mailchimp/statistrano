module Statistrano
  module Deployment

    class Manifest

      attr_reader :releases

      def initialize path
        @releases = []
        @path = path
      end

      def update
      end

      def create
      end

      def get
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