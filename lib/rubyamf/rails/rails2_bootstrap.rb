require 'rubyamf/rails/controller'
require 'rubyamf/rails/model'
require 'rubyamf/rails/request_processor'
require 'rubyamf/rails/routing'
require 'rubyamf/rails/time'
require 'action_controller'

# Hook up MIME type
Mime::Type.register RubyAMF::MIME_TYPE, :amf

# Hook routing into routes
ActionController::Routing::RouteSet::Mapper.send(:include, RubyAMF::Rails::Routing)

# Add some utility methods to ActionController
ActionController::Base.send(:include, RubyAMF::Rails::Controller)

# Hook up ActiveRecord Model extensions
if defined?(ActiveRecord)
  ActiveRecord::Base.send(:include, RubyAMF::Rails::Model)
end

# Hook up rendering and hack in our custom error handling
module ActionController #:nodoc:
  class Base #:nodoc:
    def render_with_amf(options = nil, extra_options ={}, &block)
      if options && options.is_a?(Hash) && options.has_key?(:amf)
        @performed_render = true
        @amf_response = options[:amf]
        @mapping_scope = options[:class_mapping_scope] || options[:mapping_scope] || nil
      else
        render_without_amf(options, extra_options, &block)
      end
    end
    alias_method_chain :render, :amf
  end

  module Rescue #:nodoc:
    protected
    # Re-raise the exception so that RubyAMF gets it if it's an AMF call. Otherwise
    # RubyAMF doesn't know that the call failed and a "success" response is sent.
    def rescue_action_with_amf(exception)
      raise exception if respond_to?(:is_amf?) && is_amf?
      rescue_action_without_amf exception
    end
    alias_method_chain :rescue_action, :amf
  end
end

# Add middleware
add_middleware = Proc.new {
  m = Rails.configuration.middleware
  m.use RubyAMF::RequestParser
  m.use RubyAMF::Rails::RequestProcessor
}
if Rails.initialized?
  add_middleware.call
else
  Rails.configuration.after_initialize &add_middleware
end

module RubyAMF
  def self.configure
    # Load legacy config if they have one
    begin
      RubyAMF.configuration.load_legacy
    rescue
      RubyAMF.logger.info "RubyAMF: Could not find legacy config file to load"
    end

    yield configuration
    bootstrap
  end
end