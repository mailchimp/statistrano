module Statistrano
  module Deployment

    class Releases < Base

      class Config < Base::Config
        attr_accessor :release_count
        attr_accessor :release_dir
        attr_accessor :public_dir
        attr_accessor :git_branch

        def initialize
          yield(self) if block_given?
        end
      end

      def initialize name
        super name
        @config = Config.new do |c|
          c.release_count = 5
          c.release_dir = "releases"
          c.public_dir = "current"
        end
      end

    end

  end
end