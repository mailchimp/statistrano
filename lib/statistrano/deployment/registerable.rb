module Statistrano
  module Deployment

    module Registerable
      def register_strategy name
        Strategy.register( self, name )
      end
    end

  end
end