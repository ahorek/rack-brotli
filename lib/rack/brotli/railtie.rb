# frozen_string_literal: true

module Rack
  module Brotli
    class Railtie < ::Rails::Railtie
      initializer "rack-brotli.middleware" do |app|
        app.middleware.use(Rack::Brotli)
      end
    end
  end
end 