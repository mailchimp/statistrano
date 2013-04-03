module Statistrano
  module Deployment

    class Branches < Base

      class Config < Base::Config
        attr_accessor :public_dir

        def initialize
          yield(self) if block_given?
        end
      end

      def initialize name
        super name
        @config = Config.new do |c|
          c.public_dir = Git.current_branch.to_slug
        end
      end

    end

  end
end