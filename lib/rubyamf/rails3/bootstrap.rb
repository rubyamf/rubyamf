require 'rubyamf/rails3/action_controller'
require 'rubyamf/rails3/request_processor'

module RubyAMF
  class Railtie < Rails::Railtie
    config.rubyamf = RubyAMF.configuration

    initializer "rubyamf.configure" do
      RubyAMF.bootstrap
    end

    initializer "rubyamf.middleware" do
      config.app_middleware.use RubyAMF::RequestParser, config.rubyamf.gateway_path, Rails.logger
      config.app_middleware.use RubyAMF::Rails3::RequestProcessor, Rails.logger
    end
  end
end
