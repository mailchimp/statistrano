require 'erb'

module Statistrano
  module Deployment
    module Strategy
      class Branches

        class Index

          attr_reader :template, :releases

          def initialize releases, template_path=nil
            @releases = releases
            @template = IO.read(template_path || File.expand_path("../index/template.html.erb", __FILE__))
          end

          def to_html
            ERB.new(template).result(ERBContext.new(releases).get_binding)
          end

          class ERBContext

            attr_reader :releases

            def initialize releases
              @releases = releases
            end

            def get_binding
              binding
            end

          end

        end

      end
    end
  end
end