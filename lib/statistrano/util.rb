module Statistrano
  module Util

    class << self

      def symbolize_hash_keys hash
        hash.inject({}) do |out, (key, value)|
          k = case key
              when String then key.to_sym
              else key
              end
          v = case value
              when Hash  then symbolize_hash_keys(value)
              when Array then value.map { |h| symbolize_hash_keys(h) }
              else value
              end
          out[k] = v
          out
        end
      end

    end

  end
end