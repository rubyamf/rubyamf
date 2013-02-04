module RubyAMF
  # Advanced mapping container to support various serialization customization
  # settings. Used by RubyAMF class mapper to store advanced mappings.
  class MappingSet < ::RocketAMF::MappingSet
    # Store all property mapping configuration by scope
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

    # Map a given actionscript class to a ruby class. You can also control which
    # properties are serialized using <tt>:except</tt>, <tt>:only</tt>,
    # <tt>:methods</tt>, <tt>:include</tt> for relations, and <tt>:ignore_fields</tt>
    # for skipping certain fields during deserialization.
    #
    # Use fully qualified names for both.
    #
    # Examples:
    #
    #   m.map :as => 'com.example.Date', :ruby => 'Example::Date'
    #   m.map :flash => 'User', :ruby => 'User', :only => 'username'
    #   m.map :flash => 'User', :ruby => 'User', :scope => :other, :include => [:courses, :teacher]
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

    # Returns the actionscript class name mapped to the given ruby class name.
    # Returns <tt>nil</tt> if not found.
    def get_as_class_name ruby_class_name
      mapping = @ruby_mappings[ruby_class_name]
      return mapping.nil? ? nil : mapping.as
    end

    # Returns the ruby class name mapped to the given actionscript class name.
    # Returns <tt>nil</tt> if not found.
    def get_ruby_class_name as_class_name
      mapping = @as_mappings[as_class_name]
      return mapping.nil? ? nil : mapping.ruby
    end

    # Returns the property serialization config for the given ruby class name
    # and scope. If scope is <tt>nil</tt>, it uses the default scope.
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

  # Advanced class mapper based off of RocketAMF class mapper. Adds support for
  # advanced serialization and deserialization.
  class ClassMapping < ::RocketAMF::ClassMapping
    # Override RocketAMF#mappings to return new RubyAMF::MappingSet object rather
    # than RocketAMF::MappingSet
    def self.mappings
      @mappings ||= RubyAMF::MappingSet.new
    end

    # The mapping scope to use during serialization. This is populated during
    # response serialization automatically by RubyAMF::Envelope.
    attr_accessor :mapping_scope

    # Return the actionscript class name for the given ruby object. If the object
    # is a string, that is assumed to be the ruby class name. Otherwise it extracts
    # the ruby class name from the object based on its type. As RocketAMF calls
    # this for all objects on serialization, auto-mapping takes place here if
    # enabled.
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

    # Creates a ruby object to populate during deserialization for the given
    # actionscript class name. If that actionscript class name is mapped to a
    # ruby class, an object of that class is created using
    # <tt>obj = ruby_class_name.constantize.allocate</tt> and then
    # <tt>:initialize</tt> is sent to the new instance unless it implements
    # <tt>rubyamf_init</tt>. If no ruby class name is defined, a
    # <tt>RocketAMF::Values::TypedHash</tt> object is created and its type
    # attribute is set to the actionscript class name. As RocketAMF calls this
    # for all objects on deserialization, auto-mapping takes place here if enabled.
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

    # Performs all enabled property translations (case, key type, ignore_fields)
    # before passing to <tt>rubyamf_init</tt> if implemented, or to the RocketAMF
    # class mapper implementation.
    def populate_ruby_obj obj, props, dynamic_props=nil
      # Translate case of properties before passing down to super
      if RubyAMF.configuration.translate_case && !obj.is_a?(RocketAMF::Values::AbstractMessage)
        case_translator = lambda {|injected, pair| injected[pair[0].underscore] = pair[1]; injected}
        props = props.inject({}, &case_translator)
        dynamic_props = dynamic_props.inject({}, &case_translator) if dynamic_props
      end

      # Convert hash key type to string if it's a hash
      if RubyAMF.configuration.hash_key_access == :symbol && obj.is_a?(Hash)
        key_change = lambda {|injected, pair| injected[pair[0].to_sym] = pair[1]; injected}
        props = props.inject({}, &key_change)
        dynamic_props = dynamic_props.inject({}, &key_change) if dynamic_props
      end

      # Remove ignore_fields if there is a config
      config = @mappings.serialization_config(obj.class.name, mapping_scope) || {}
      ignore_fields = Array.wrap(config[:ignore_fields])
      ignore_fields = RubyAMF.configuration.ignore_fields unless ignore_fields.any?
      ignore_fields.each do |ignore|
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

    # Extracts a hash of all object properties for serialization from the object,
    # using <tt>rubyamf_hash</tt> if implemented with the proper mapping configs
    # for the scope, or the RocketAMF implementation. Before being returned to
    # the serializer, case translation is performed if enabled.
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