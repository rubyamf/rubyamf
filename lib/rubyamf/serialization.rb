module RubyAMF
  module Serialization
    def self.included base
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def as_class class_name
        @as_class = class_name.to_s
        RubyAMF::ClassMapper.mappings.map :as => @as_class, :ruby => self.name
      end
      alias :actionscript_class :as_class
      alias :flash_class :as_class

      def map_amf scope_or_options=nil, options=nil
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

      # Build hash
      hash = {}
      attribute_names.each {|name| hash[name] = saved_attributes[name]}
      method_names.each {|name| hash[name] = send(name)}
      hash
    end
  end
end