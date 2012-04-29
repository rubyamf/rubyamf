module RubyAMF
  # Simply include in your ruby object to enable advanced serialization features
  # like an in-model mapping API, customizable initialization after
  # deserialization, scoped property configuration for serialization, and several
  # other things. See RubyAMF::Model::ClassMethods for details of in-model mapping
  # API.
  #
  # Example:
  #
  #   class SerializableObject
  #     include RubyAMF::Model
  #
  #     as_class "com.rubyamf.ASObject"
  #     map_amf :only => "prop_a"
  #
  #     attr_accessor :prop_a, :prop_b
  #   end
  #
  # == Integration
  #
  # If the object you include RubyAMF::Model into implements <tt>attributes</tt>
  # and <tt>attributes=</tt>, those two methods will be automatically used to
  # determine serializable properties and to set them after deserialization. If
  # you do not implement those methods, attributes will be guessed by going through
  # all methods that don't take arguments, and attribute setters will be used
  # rather than <tt>attributes=</tt>.
  #
  # For most ORMs, the provided <tt>rubyamf_init</tt>, <tt>rubyamf_hash</tt>, and
  # <tt>rubyamf_retrieve_association</tt> should work correctly. However, they
  # can be overridden to provide custom behavior if the default has issues with
  # the ORM you are using. See RubyAMF::Rails::Model for an example of ORM-specific
  # customization.
  module Model
    def self.included base #:nodoc:
      base.send :extend, ClassMethods
    end

    # In-model mapping configuration methods
    module ClassMethods
      # Specify the actionscript class name that this class maps to.
      #
      # Example:
      #
      #   class SerializableObject
      #     include RubyAMF::Model
      #     as_class "com.rubyamf.ASObject"
      #   end
      def as_class class_name
        @as_class = class_name.to_s
        RubyAMF::ClassMapper.mappings.map :as => @as_class, :ruby => self.name
      end
      alias :actionscript_class :as_class
      alias :flash_class :as_class
      alias :amf_class :as_class

      # Define a parameter mapping for the default scope or a given scope. If the
      # first parameter is a hash, it looks for a <tt>:default_scope</tt> key to
      # set the default scope and scope the given configuration, and parses the
      # other keys like <tt>serializable_hash</tt> does. If the first argument
      # is a symbol, that symbol is assumed to be the scope for the given
      # configuration. Just like <tt>serializable_hash</tt>, it supports
      # <tt>:except</tt>, <tt>:only</tt>, <tt>:methods</tt>, and <tt>:include</tt>
      # for relations. It also has an <tt>:ignore_fields</tt> configuration for
      # skipping certain fields during deserialization if the actionscript object
      # contains extra fields or to protect yourself from modification of
      # protected properties. <tt>:ignore_fields</tt> must be defined on the
      # default scope, or it will be ignored.
      #
      # Example:
      #
      #   class SerializableObject
      #     include RubyAMF::Model
      #     as_class "com.rubyamf.ASObject"
      #     map_amf :only => "prop_a"
      #     map_amf :testing, :only => "prop_b"
      #     map_amf :default_scope => :asdf, :only => "prop_c", :ignore_fields => ["password", "password_confirm"]
      #   end
      def map_amf scope_or_options=nil, options=nil
        # Make sure they've already called as_class first
        raise "Must define as_class first" unless @as_class

        # Format parameters to pass to RubyAMF::MappingSet#map
        if options
          options[:scope] = scope_or_options
        else
          options = scope_or_options
        end
        options[:as] = @as_class
        options[:ruby] = self.name
        RubyAMF::ClassMapper.mappings.map options
      end
    end

    # Populates the object after deserialization. By default it calls initialize,
    # calls setters for keys not in attributes, and calls <tt>attributes=</tt> for
    # the remaining properties if it's implemented. Override if necessary to
    # support your ORM.
    def rubyamf_init props, dynamic_props = nil
      initialize # warhammerkid: Call initialize by default - good decision?

      props.merge!(dynamic_props) if dynamic_props
      if respond_to?(:attributes=)
        attrs = self.attributes
        rubyamf_set_non_attributes props, attrs
        self.attributes = props # Populate using attributes setter
      else
        rubyamf_set_non_attributes props, {} # Calls setters for all props it finds setters for
      end
    end

    # Calls setters for all keys in the given hash not found in the base attributes
    # hash and deletes those keys from the hash. Performs some simple checks on
    # the keys to hopefully prevent more private setters from being called.
    def rubyamf_set_non_attributes attrs, base_attrs
      not_attributes = attrs.keys.select {|k| !base_attrs.include?(k)}
      not_attributes.each do |k|
        setter = "#{k}="
        next if setter !~ /^[a-z][A-Za-z0-9_]*=/ # Make sure setter doesn't start with capital, dollar, or underscore to make this safer
        if respond_to?(setter)
          send(setter, attrs.delete(k))
        else
          RubyAMF.logger.warn("RubyAMF: Cannot call setter for non-attribute on #{self.class.name}: #{k}")
        end
      end
    end

    # Like serializable_hash, rubyamf_hash returns a hash for serialization
    # calculated from the given options. Supported options are <tt>:only</tt>,
    # <tt>:except</tt>, <tt>:methods</tt>, and <tt>:include</tt>. This method
    # is automatically called by RubyAMF::ClassMapping on serialization with
    # the pre-configured options for whatever the current scope is.
    def rubyamf_hash options=nil
      # Process options
      options ||= {}
      only = Array.wrap(options[:only]).map(&:to_s)
      except = Array.wrap(options[:except]).map(&:to_s)
      method_names = []
      Array.wrap(options[:methods]).each do |name|
        method_names << name.to_s if respond_to?(name)
      end

      # Get list of attributes
      if respond_to?(:attributes)
        attrs = send(:attributes)
      else
        attrs = {}
        ignored_props = Object.new.public_methods
        (self.public_methods - ignored_props).each do |method_name|
          # Add them to the attrs hash if they take no arguments
          method_def = self.method(method_name)
          attrs[method_name.to_s] = send(method_name) if method_def.arity == 0
        end
      end
      attribute_names = attrs.keys.sort
      if only.any?
        attribute_names &= only
      elsif except.any?
        attribute_names -= except
      end

      # Build hash from attributes and methods
      hash = {}
      attribute_names.each {|name| hash[name] = attrs[name]}
      method_names.each {|name| hash[name] = send(name)}

      # Add associations using ActiveRecord::Serialization style options
      # processing
      if include_associations = options.delete(:include)
        # Process options
        base_only_or_except = {:except => options[:except], :only => options[:only]}
        include_has_options = include_associations.is_a?(Hash)
        associations = include_has_options ? include_associations.keys : Array.wrap(include_associations)

        # Call to_amf on each object in the association, passing processed options
        associations.each do |association|
          records = rubyamf_retrieve_association(association)
          if records
            opts = include_has_options ? include_associations[association] : nil
            if records.is_a?(Enumerable)
              hash[association.to_s] = records.map {|r| opts.nil? ? r : r.to_amf(opts)}
            else
              hash[association.to_s] = opts.nil? ? records : records.to_amf(opts)
            end
          end
        end

        options[:include] = include_associations
      end

      hash
    end

    # Override if necessary to support your ORM's system of retrieving objects
    # in an association.
    def rubyamf_retrieve_association association
      # Naive implementation that should work for most cases without
      # need for overriding
      send(association)
    end

    # Stores the given options and object in an IntermediateObject so that the
    # default serialization mapping options can be overriden if necessary.
    def to_amf options=nil
      RubyAMF::IntermediateObject.new(self, options)
    end
  end
end

class Array
  # Returns an array of RubyAMF::IntermediateObject objects created from calling
  # <tt>to_amf</tt> on each object in the array with the given options.
  def to_amf options=nil
    self.map {|o| o.to_amf(options)}
  end
end