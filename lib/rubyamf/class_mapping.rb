module RubyAMF
  class MappingSet < ::RocketAMF::MappingSet
    class Mapping
      attr_accessor :ruby, :as, :default_scope, :scopes
      def initialize
        @default_scope = :default
        @scopes = {}
      end
    end

    SERIALIZATION_PROPS = [:except, :only, :methods, :include]

    def initialize
      @as_mappings = {}
      @ruby_mappings = {}
      map_defaults
    end

    def map params
      # Extract and validate ruby and AS class names
      ruby_class = params[:ruby]
      as_class = params[:flash] || params[:as] || params[:actionscript]
      raise "Must pass ruby class name under :ruby key" unless ruby_class
      raise "Must pass as class name under :flash, :as, or :actionscript key" unless as_class

      # Get mapping if it already exists
      mapping = @as_mappings[as_class] || @ruby_mappings[ruby_class] || Mapping.new
      mapping.ruby = ruby_class
      mapping.as = as_class
      @as_mappings[as_class] = mapping
      @ruby_mappings[ruby_class] = mapping

      # If they tried to configure the serialization props, store that too under the proper scope
      serialization_config = {}
      params.each {|k,v| serialization_config[k] = v if SERIALIZATION_PROPS.include?(k)}
      if serialization_config.length > 0
        # Determine scope
        scope = nil
        if params[:default_scope]
          scope = mapping.default_scope = params[:default_scope]
        elsif params[:scope]
          scope = params[:scope]
        else
          scope = mapping.default_scope
        end

        # Add config to scope hash
        mapping.scopes[scope] = serialization_config
      end
    end

    def get_as_class_name ruby_class_name
      return @ruby_mappings[ruby_class_name].as
    end

    def get_ruby_class_name as_class_name
      return @as_mappings[as_class_name].ruby
    end

    def serialization_config ruby_class_name, scope = nil
      mapping = @ruby_mappings[ruby_class_name]
      scope ||= mapping.default_scope
      return mapping.scopes[scope]
    end
  end
end