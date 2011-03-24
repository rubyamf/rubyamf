require 'rubyamf/rails/action_controller'
require 'rubyamf/rails/request_processor'

class ActionController::Base
  def render_with_amf(options = nil, extra_options ={}, &block)
    if options && options.is_a?(Hash) && options.has_key?(:amf)
      @performed_render = true
      @amf_response = options[:amf]
    else
      render_without_amf(options, extra_options, &block)
    end
  end
  alias_method_chain :render, :amf
end

module RubyAMF::Rails2
  def bootstrap
    super
    m = ::Rails.configuration.middleware
    m.use RubyAMF::RequestParser
    m.use RubyAMF::Rails::RequestProcessor
  end
end
RubyAMF.send(:extend, RubyAMF::Rails2)