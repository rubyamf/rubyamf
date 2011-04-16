module RubyAMF::Rails
  module Routing
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
      modules.reverse.each {|m| controller = "#{m}::#{controller}"}

      RubyAMF.configuration.map_params controller, action, params
    end
    alias_method :amf, :map_amf
  end
end