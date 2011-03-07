require 'rubyamf/rails2/action_controller'
require 'rubyamf/rails2/request_processor'

module RubyAMF
  class << self
    alias_method :old_bootstrap, :bootstrap
    def bootstrap
      old_bootstrap

      m = Rails.configuration.middleware
      m.use RubyAMF::RequestParser, RubyAMF.configuration.gateway_path, Rails.logger
      m.use RubyAMF::Rails2::RequestProcessor, Rails.logger
    end
  end
end