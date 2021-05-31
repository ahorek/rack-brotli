require_relative 'brotli/deflater'
require_relative 'brotli/version'
require_relative 'brotli/railtie' if defined?(::Rails)

module Rack
  module Brotli
    def self.release
      Version.to_s
    end

    def self.new(app, options={})
      Rack::Brotli::Deflater.new(app, options)
    end
  end
end
