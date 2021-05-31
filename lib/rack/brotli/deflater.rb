# frozen_string_literal: true

require "brotli"
require 'rack/utils'

module Rack::Brotli
  # This middleware enables compression of http responses.
  #
  # Currently supported compression algorithms:
  #
  #   * br
  #
  # The middleware automatically detects when compression is supported
  # and allowed. For example no transformation is made when a cache
  # directive of 'no-transform' is present, or when the response status
  # code is one that doesn't allow an entity body.
  class Deflater
    ##
    # Creates Rack::Brotli middleware.
    #
    # [app] rack app instance
    # [options] hash of deflater options, i.e.
    #           'if' - a lambda enabling / disabling deflation based on returned boolean value
    #                  e.g use Rack::Brotli, :if => lambda { |env, status, headers, body| body.map(&:bytesize).reduce(0, :+) > 512 }
    #           'include' - a list of content types that should be compressed
    #           'deflater' - Brotli compression options
    def initialize(app, options = {})
      @app = app

      @condition = options[:if]
      @compressible_types = options[:include]
      if defined?(ActiveSupport::Notifications)
        @notifier = ActiveSupport::Notifications
      else
        @notifier = Rack::Brotli::Instrument
      end
      @deflater_options = { quality: 5 }
      @deflater_options.merge!(options[:deflater]) if options[:deflater]
      @deflater_options
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers = header_hash(headers)

      unless should_deflate?(env, status, headers, body)
        return [status, headers, body]
      end

      request = Rack::Request.new(env)

      encoding = Rack::Utils.select_best_encoding(%w(br),
                                            request.accept_encoding)

      return [status, headers, body] unless encoding

      instrument(request) do
        # Set the Vary HTTP header.
        vary = headers["Vary"].to_s.split(",").map(&:strip)
        unless vary.include?("*") || vary.include?("Accept-Encoding")
          headers["Vary"] = vary.push("Accept-Encoding").join(",")
        end

        case encoding
        when "br"
          headers['Content-Encoding'] = "br"
          headers.delete('Content-Length')
          [status, headers, BrotliStream.new(body, @deflater_options)]
        when nil
          message = "An acceptable encoding for the requested resource #{request.fullpath} could not be found."
          bp = Rack::BodyProxy.new([message]) { body.close if body.respond_to?(:close) }
          [406, {'Content-Type' => "text/plain", 'Content-Length' => message.length.to_s}, bp]
        end
      end
    end

    class BrotliStream
      include Rack::Utils

      def initialize(body, options)
        @body = body
        @options = options
      end

      def each(&block)
        @writer = block
        buffer = +''
        @body.each { |part|
          buffer << part
        }
        yield ::Brotli.deflate(buffer, @options)
      ensure
        @writer = nil
      end

      def close
        @body.close if @body.respond_to?(:close)
      end
    end
    
    private

    # instrument for performance metrics
    def instrument(request, &block)
      @notifier.instrument("rack.brotli", request: request) do
        yield
      end
    end

    def header_hash(headers)
      if headers.is_a?(Rack::Utils::HeaderHash)
        header
      else
        Rack::Utils::HeaderHash.new(headers) # rack < 2.2
      end
    end

    def should_deflate?(env, status, headers, body)
      # Skip compressing empty entity body responses and responses with
      # no-transform set.
      if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.key?(status.to_i) ||
          /\bno-transform\b/.match?(headers['Cache-Control'].to_s) ||
          headers['Content-Encoding']&.!~(/\bidentity\b/)
        return false
      end

      # Skip if @compressible_types are given and does not include request's content type
      return false if @compressible_types && !(headers.has_key?('Content-Type') && @compressible_types.include?(headers['Content-Type'][/[^;]*/]))

      # Skip if @condition lambda is given and evaluates to false
      return false if @condition && !@condition.call(env, status, headers, body)

      # No point in compressing empty body, also handles usage with
      # Rack::Sendfile.
      return false if headers['Content-Length'] == '0'

      true
    end
  end
end
