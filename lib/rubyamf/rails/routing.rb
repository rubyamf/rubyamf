module RubyAMF
  module Rails
    module Routing
      def map_amf options, params=nil
        # Extract controller and action
        if options.is_a?(String)
          (controller, action) = options.split("#")
        else
          controller = options[:controller]
          action = options[:action]
          params = options[:params]
        end

        # Convert controller name to actual controller class name
        controller = controller.camelize(:upper)+"Controller"

        RubyAMF.configuration.map_params controller, action, params
      end
      alias_method :amf, :map_amf
    end
  end
end

if Rails::VERSION::MAJOR == 3
  ActionDispatch::Routing::Mapper.send(:include, RubyAMF::Rails::Routing)
else
  ActionController::Routing::RouteSet::Mapper.send(:include, RubyAMF::Rails::Routing)
end