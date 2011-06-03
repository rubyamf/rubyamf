require 'rubyamf/rails/controller'
require 'rubyamf/rails/model'
require 'rubyamf/rails/request_processor'
require 'rubyamf/rails/routing'
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

# Hook up rendering
class ActionController::Base
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

module RubyAMF::Rails2
  def bootstrap
    # Load legacy config if they have one
    begin
      RubyAMF.configuration.load_legacy
    rescue
      RubyAMF.logger.info "RubyAMF: Could not find legacy config file to load"
    end

    super

    # Rails specific bootstrapping
    m = ::Rails.configuration.middleware
    m.use RubyAMF::RequestParser
    m.use RubyAMF::Rails::RequestProcessor
  end
end
RubyAMF.send(:extend, RubyAMF::Rails2)