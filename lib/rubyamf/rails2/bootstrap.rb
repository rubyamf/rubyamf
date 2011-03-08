require 'rubyamf/rails/action_controller'
require 'rubyamf/rails2/action_controller'
require 'rubyamf/rails/request_processor'

module RubyAMF::Rails2
  def bootstrap
    super
    m = ::Rails.configuration.middleware
    m.use RubyAMF::RequestParser, RubyAMF.configuration.gateway_path, ::Rails.logger
    m.use RubyAMF::Rails::RequestProcessor, ::Rails.logger
  end
end
RubyAMF.send(:extend, RubyAMF::Rails2)