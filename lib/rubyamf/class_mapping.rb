module RubyAMF
  class MappingSet < ::RocketAMF::MappingSet
    class Mapping
      attr_accessor :ruby, :as, :default_scope, :scopes
      def initialize
        @default_scope = :default
        @scopes = {}
      end
    end

    SERIALIZATION_PROPS = [:except, :only, :methods, :include, :ignore_fields]

    def initialize
      @as_mappings = {}
      @ruby_mappings = {}
      map_defaults
    end

    def map params
      # Extract and validate ruby and AS class names
      ruby_class = params[:ruby]
      as_class = params[:as] || params[:flash] || params[:actionscript]
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
        mapping.scopes[scope.to_sym] = serialization_config
      end
    end

    def get_as_class_name ruby_class_name
      mapping = @ruby_mappings[ruby_class_name]
      return mapping.nil? ? nil : mapping.as
    end

    def get_ruby_class_name as_class_name
      mapping = @as_mappings[as_class_name]
      return mapping.nil? ? nil : mapping.ruby
    end

    def serialization_config ruby_class_name, scope = nil
      mapping = @ruby_mappings[ruby_class_name]
      if mapping.nil?
        nil
      else
        scope ||= mapping.default_scope
        mapping.scopes[scope.to_sym]
      end
    end
  end

  class ClassMapping < ::RocketAMF::ClassMapping
    def self.mappings
      @mappings ||= RubyAMF::MappingSet.new
    end

    attr_accessor :mapping_scope # nil uses proper default calculations

    def get_as_class_name obj
      # Get class name
      if obj.is_a?(String)
        ruby_class_name = obj
      elsif obj.is_a?(RocketAMF::Values::TypedHash)
        ruby_class_name = obj.type
      elsif obj.is_a?(Hash)
        return nil
      elsif obj.is_a?(RubyAMF::IntermediateObject)
        ruby_class_name = obj.object.class.name
      else
        ruby_class_name = obj.class.name
      end

      # Get AS class name
      as_class_name = @mappings.get_as_class_name ruby_class_name

      # Auto-map if necessary, removing namespacing to create mapped class name
      if RubyAMF.configuration.auto_class_mapping && ruby_class_name && as_class_name.nil?
        as_class_name = ruby_class_name.split('::').pop
        @mappings.map :as => as_class_name, :ruby => ruby_class_name
      end

      as_class_name
    end

    def get_ruby_obj as_class_name
      # Get ruby class name
      ruby_class_name = @mappings.get_ruby_class_name as_class_name

      # Auto-map if necessary, removing namespacing to create mapped class name
      if RubyAMF.configuration.auto_class_mapping && as_class_name && ruby_class_name.nil?
        ruby_class_name = as_class_name.split('.').pop
        @mappings.map :as => as_class_name, :ruby => ruby_class_name
      end

      # Create ruby object
      if ruby_class_name.nil?
        return RocketAMF::Values::TypedHash.new(as_class_name)
      else
        ruby_class = ruby_class_name.constantize
        obj = ruby_class.allocate
        obj.send(:initialize) unless obj.respond_to?(:rubyamf_init) # warhammerkid: Should we check if it has initialize?
        return obj
      end
    end

    def populate_ruby_obj obj, props, dynamic_props=nil
      # Translate case of properties before passing down to super
      if RubyAMF.configuration.translate_case && !obj.is_a?(RocketAMF::Values::AbstractMessage)
        case_translator = lambda {|injected, pair| injected[pair[0].to_s.underscore.to_sym] = pair[1]; injected}
        props = props.inject({}, &case_translator)
        dynamic_props = dynamic_props.inject({}, &case_translator) if dynamic_props
      end

      # Convert hash key type to string if it's a hash
      if RubyAMF.configuration.hash_key_access == :string && obj.is_a?(Hash)
        key_change = lambda {|injected, pair| injected[pair[0].to_s] = pair[1]; injected}
        props = props.inject({}, &key_change)
        dynamic_props = dynamic_props.inject({}, &key_change) if dynamic_props
      end

      # Remove ignore_fields if there is a config
      config = @mappings.serialization_config(obj.class.name, mapping_scope) || {}
      Array.wrap(config[:ignore_fields]).each do |ignore|
        props.delete(ignore.to_s)
        props.delete(ignore.to_sym)
        if dynamic_props
          dynamic_props.delete(ignore.to_s)
          dynamic_props.delete(ignore.to_sym)
        end
      end

      # Handle custom init
      if obj.respond_to?(:rubyamf_init)
        obj.rubyamf_init props, dynamic_props
      else
        # Fall through to default populator
        super(obj, props, dynamic_props)
      end
    end

    def props_for_serialization ruby_obj
      props = nil

      # Get properties for serialization
      if ruby_obj.respond_to?(:rubyamf_hash)
        if ruby_obj.is_a?(RubyAMF::IntermediateObject)
          props = ruby_obj.rubyamf_hash
        else
          config = @mappings.serialization_config(ruby_obj.class.name, mapping_scope)
          props = ruby_obj.rubyamf_hash config
        end
      else
        # Fall through to default handlers
        props = super(ruby_obj)
      end

      # Translate case of properties if necessary
      if RubyAMF.configuration.translate_case
        props = props.inject({}) do |injected, pair|
          injected[pair[0].to_s.camelize(:lower)] = pair[1]
          injected
        end
      end

      props
    end
  end
end