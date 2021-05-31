# dummy implementation for non-rails environments

module Rack
  module Brotli
    class Instrument
      def self.instrument(name, **args, &block)
        yield
      end
    end
  end
end
