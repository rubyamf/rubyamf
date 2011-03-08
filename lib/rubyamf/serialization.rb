module RubyAMF
  module Serialization
    PLUGINS = {
      "ActiveRecord::Base" => 'rubyamf/serialization/active_record'
    }

    def self.included base
      base.send :extend, ClassMethods
    end

    # Detect ORMs and load support hooks for them
    def self.load_support
      # Key is the constant to look for and value is the file to require to add
      # support for that ORM. Key is assumed to be a string with support for
      # namespacing. For example: "ActiveRecord::Base"
      PLUGINS.each do |const, file|
        # Is the plugin constant defined?
        parts = const.split("::")
        const_is_defined = true
        base = Object
        while part = parts.shift
          if base.const_defined?(part)
            base = base.const_get(part)
          else
            const_is_defined = false
            break
          end
        end

        require file if const_is_defined
      end
    end

    module ClassMethods
      def as_class class_name
        @as_class = class_name.to_s
        RubyAMF::ClassMapper.mappings.map :as => @as_class, :ruby => self.name
      end
      alias :actionscript_class :as_class
      alias :flash_class :as_class
      alias :amf_class :as_class

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

    def rubyamf_hash options=nil
      raise "Must implement attributes method for rubyamf_hash to work" unless respond_to?(:attributes)

      # Process options
      options ||= {}
      only = RubyAMF.array_wrap(options[:only]).map(&:to_s)
      except = RubyAMF.array_wrap(options[:except]).map(&:to_s)
      method_names = []
      RubyAMF.array_wrap(options[:methods]).each do |name|
        method_names << name.to_s if respond_to?(name)
      end

      # Get list of attributes
      saved_attributes = attributes
      attribute_names = saved_attributes.keys.sort
      if only.any?
        attribute_names &= only
      elsif except.any?
        attribute_names -= except
      end

      # Build hash from attributes and methods
      hash = {}
      attribute_names.each {|name| hash[name] = saved_attributes[name]}
      method_names.each {|name| hash[name] = send(name)}

      # Add associations using ActiveRecord::Serialization style options
      # processing
      if include_associations = options.delete(:include)
        # Process options
        base_only_or_except = {:except => options[:except], :only => options[:only]}
        include_has_options = include_associations.is_a?(Hash)
        associations = include_has_options ? include_associations.keys : RubyAMF.array_wrap(include_associations)

        for association in associations
          records = rubyamf_retrieve_association(association)
          unless records.nil?
            association_options = include_has_options ? include_associations[association] : base_only_or_except
            opts = options.merge(association_options)

            if records.is_a?(Enumerable)
              hash[association.to_s] = records.map {|r| r.rubyamf_hash(opts)}
            else
              hash[association.to_s] = records.rubyamf_hash(opts)
            end
          end
        end

        options[:include] = include_associations
      end

      hash
    end

    def rubyamf_retrieve_association association
      # Naive implementation that should work for most cases without
      # need for overriding
      send(association)
    end

    def to_amf options=nil
      RubyAMF::IntermediateObject.new(self, options)
    end
  end
end

# Map array to_amf calls to each element
class Array
  def to_amf options=nil
    self.map {|o| o.to_amf(options)}
  end
end