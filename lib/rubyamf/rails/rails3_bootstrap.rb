require 'rubyamf/rails/action_controller'
require 'rubyamf/rails/request_processor'

# Hook up rendering
ActionController::Renderers.add :amf do |amf, options|
  @amf_response = amf
  self.content_type ||= Mime::AMF
  self.response_body = " "
end

class RubyAMF::Railtie < Rails::Railtie
  config.rubyamf = RubyAMF.configuration

  initializer "rubyamf.configured" do
    RubyAMF.bootstrap
  end

  initializer "rubyamf.middleware" do
    config.app_middleware.use RubyAMF::RequestParser
    config.app_middleware.use RubyAMF::Rails::RequestProcessor
  end
end