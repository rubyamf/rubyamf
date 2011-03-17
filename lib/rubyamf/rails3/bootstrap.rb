require 'rubyamf/rails/action_controller'
require 'rubyamf/rails3/action_controller'
require 'rubyamf/rails/request_processor'

class RubyAMF::Railtie < Rails::Railtie
  config.rubyamf = RubyAMF.configuration

  initializer "rubyamf.configured" do
    RubyAMF.bootstrap
  end

  initializer "rubyamf.middleware" do
    config.app_middleware.use RubyAMF::RequestParser, config.rubyamf.gateway_path
    config.app_middleware.use RubyAMF::Rails::RequestProcessor
  end
end