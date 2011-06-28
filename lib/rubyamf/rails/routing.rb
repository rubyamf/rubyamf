module RubyAMF::Rails
  # The prefered method for parameter mapping in Rails is through the routing
  # file. RubyAMF supports namespacing for controllers and several different
  # syntax styles for better integration into Rails 2 or Rails 3. This module
  # can also be used outside of Rails by including it wherever you want.
  module Routing
    # Define a parameter mapping
    #
    # ===Rails 2
    #
    #   ActionController::Routing::Routes.draw do |map|
    #     map.amf :controller => "controller", :action => "action", :params => [:param1, :param2]
    #     map.namespace :admin do |admin|
    #       admin.amf "controller#action", [:param1, :param2]
    #     end
    #   end
    #
    # ===Rails 3
    #
    #   AmfApplication::Application.routes.draw do |map|
    #     map_amf "controller#action", [:param1, :param2]
    #     namespace :admin do
    #       map_amf "controller#action", [:param1, :param2]
    #     end
    #   end
    #
    # ===Generic Framework
    #
    #   include Routing
    #   # Namespace is WillBe::Camelized
    #   map_amf "controller#action", [:param1, :param2]
    #   map_amf "controller#action", [:param1, :param2], {:namespace => "will_be/camelized"}
    #   map_amf :controller => "controller", :action => "action", :params => [:param1, :param2], :namespace => "will_be/camelized"
    def map_amf *args
      # Rails 2 namespace uses ActiveSupport::OptionMerger, which adds namespace
      # options to last hash, or passes it as an additional parameter
      # Rails 3 stores current namespace info in @scope variable

      # Process args
      if args[0].is_a?(String)
        (controller, action) = args[0].split("#")
        params = args[1]
        rails2_with_options = args[2] || {}
      else
        controller = args[0].delete(:controller)
        action = args[0].delete(:action)
        params = args[0].delete(:params)
        rails2_with_options = args[0]
      end

      # Convert controller name to actual controller class name
      controller = controller.camelize(:upper)+"Controller" unless controller =~ /Controller$/

      # Namespace controller name if used
      modules = if @scope && @scope[:module]
        # Rails 3 code path
        @scope[:module].split("/").map {|n| n.camelize(:upper)}
      elsif rails2_with_options[:namespace]
        # Rails 2 code path
        namespaces = rails2_with_options[:namespace].split("/")
        namespaces.map {|n| n.camelize(:upper)}
      else
        []
      end
      modules << controller
      controller = modules.join("::")

      RubyAMF.configuration.map_params controller, action, params
    end
    alias_method :amf, :map_amf
  end
end