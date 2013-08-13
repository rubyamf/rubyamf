module RubyAMF::Rails
  # Rails-specific implementation of <tt>RubyAMF::Model</tt> APIs
  module Model
    include RubyAMF::Model

    def self.included base #:nodoc:
      base.send :extend, ClassMethods
    end

    def rubyamf_init props, dynamic_props = nil
      # Convert props and dynamic props to hash with string keys for attributes
      attrs = {}
      props.each {|k,v| attrs[k.to_s] = v}
      dynamic_props.each {|k,v| attrs[k.to_s] = v} unless dynamic_props.nil?

      # Is it a new record or existing? - support composite primary keys just in case
      is_new = true
      pk = Array.wrap(self.class.primary_key).map &:to_s
      if pk.length > 1 || pk[0] != 'id'
        unless pk.any? {|k| empty_key?(attrs, k)}
          search = pk.map {|k| attrs[k]}
          search = search.first if search.length == 1
          is_new = !self.class.exists?(search) # Look it up in the database to make sure because it may be a string PK (or composite PK)
        end
      else
        is_new = false unless empty_key?(attrs, 'id')
      end

      # Get base attributes hash for later use
      base_attrs = if ::ActiveRecord::VERSION::STRING < '3.2'
                     self.send(:attributes_from_column_definition)
                   else
                     self.class.column_defaults.dup
                   end

      if is_new
        # Call initialize to populate everything for a new object
        self.send(:initialize)

        # Populate part of given primary key
        pk.each do |k|
          self.send("#{k}=", attrs[k]) unless empty_key?(attrs, k)
        end
      else
        # Initialize with defaults so that changed properties will be marked dirty
        pk_attrs = pk.inject({}) {|h, k| h[k] = attrs[k]; h}
        base_attrs.merge!(pk_attrs)

        if ::ActiveRecord::VERSION::MAJOR == 2
          # if rails 2, use code from ActiveRecord::Base#instantiate (just copied it over)
          object = self
          object.instance_variable_set("@attributes", base_attrs)
          object.instance_variable_set("@attributes_cache", Hash.new)

          if object.respond_to_without_attributes?(:after_find)
            object.send(:callback, :after_find)
          end

          if object.respond_to_without_attributes?(:after_initialize)
            object.send(:callback, :after_initialize)
          end
        else
          # if rails 3, use init_with('attributes' => attributes_hash)
          self.init_with('attributes' => base_attrs)
        end
      end

      # Delete pk from attrs as they have already been set
      pk.each {|k| attrs.delete(k)}

      # Set associations
      (reflections = self.class.reflections).keys.each do |k|
        if value = attrs.delete(k.to_s)
          reflection_macro = reflections[k].macro
          if ::ActiveRecord::VERSION::STRING < "3.1"
            case reflection_macro
              when :has_one
                self.send("set_#{k}_target", value)
              when :belongs_to
                self.send("#{k}=", value)
              when :has_many, :has_and_belongs_to_many
                self.send("#{k}").target = value
              when :composed_of
                self.send("#{k}=", value) # this sets the attributes to the corresponding values
            end
          else
            case reflection_macro
              when :has_many, :has_and_belongs_to_many, :has_one
                self.association(k).target = value
              when :belongs_to, :composed_of
                self.send("#{k}=", value) # this sets the attributes to the corresponding values
            end
          end
        end
      end

      # Set attributes
      rubyamf_set_non_attributes attrs, base_attrs
      self.send(:attributes=, attrs)

      self
    end

    def rubyamf_hash options=nil
      return super(options) unless RubyAMF.configuration.check_for_associations

      options ||= {}

      # Iterate through assocations and check to see if they are loaded
      auto_include = []
      self.class.reflect_on_all_associations.each do |reflection|
        next if reflection.macro == :belongs_to # Skip belongs_to to prevent recursion
        is_loaded = if self.respond_to?(:association)
          # Rails 3.1
          self.association(reflection.name).loaded?
        elsif self.respond_to?("loaded_#{reflection.name}?")
          # Rails 2.3 and 3.0 for some types
          self.send("loaded_#{reflection.name}?")
        else
          # Rails 2.3 and 3.0 for some types
          self.send(reflection.name).loaded?
        end
        auto_include << reflection.name if is_loaded
      end

      # Add these assocations to the :include if they are not already there
      if include_associations = options.delete(:include)
        if include_associations.is_a?(Hash)
          auto_include.each {|assoc| include_associations[assoc] ||= {}}
        else
          include_associations = Array.wrap(include_associations) | auto_include
        end
        options[:include] = include_associations
      else
        options[:include] = auto_include if auto_include.length > 0
      end

      super(options)
    end

    def rubyamf_retrieve_association association
      case self.class.reflect_on_association(association).macro
      when :has_many, :has_and_belongs_to_many
        send(association).to_a
      when :has_one, :belongs_to
        send(association)
      end
    end

    def empty_key? attrs, key
      return true unless attrs.key?(key)
      attrs[key] == 0 || attrs[key].nil?
    end
  end
end
