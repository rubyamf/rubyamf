module RubyAMF
  class Configuration
    # Gateway options
    attr_accessor :gateway_path, :param_mappings, :populate_params_hash,
                  :show_html_gateway

    # Serialization options
    attr_accessor :translate_case, :auto_class_mapping, :use_array_collection,
                  :hash_key_access, :preload_models, :check_for_associations,
                  :ignore_fields

    def initialize
      @gateway_path = "/rubyamf/gateway"
      @param_mappings = {}
      @populate_params_hash = true
      @show_html_gateway = true

      @translate_case = false
      @auto_class_mapping = false
      @use_array_collection = false
      @hash_key_access = :symbol
      @preload_models = []
      @check_for_associations = true
      @ignore_fields = ['created_at', 'created_on', 'updated_at', 'updated_on']
    end

    def map_params controller, action, params
      @param_mappings[controller.to_s+"#"+action.to_s] = params
    end

    def class_mapper
      if @class_mapper.nil?
        @class_mapper = RubyAMF::ClassMapping
      end
      @class_mapper
    end

    def class_mapper= klass
      @class_mapper = klass
    end

    def load_legacy path=nil
      # Locate legacy config
      unless path
        possible = []
        possible << File.join(RAILS_ROOT, 'config', 'rubyamf_config.rb') if defined?(RAILS_ROOT)
        possible << File.join('config', 'rubyamf_config.rb')
        possible << 'rubyamf_config.rb'
        unless path = possible.find {|p| File.exists?(p)}
          raise "rubyamf_config.rb not found"
        end
      end

      # Load legacy config
      $" << "app/configuration" # prevent legacy code require from doing anything
      LegacySandbox.module_eval(File.read(path))
      $".pop
      cm = LegacySandbox::RubyAMF::ClassMappings
      pm = LegacySandbox::RubyAMF::ParameterMappings

      # Raise exceptions for disabled settings
      if cm.force_active_record_ids != nil; raise "CONFIG PARSE ERROR: force_active_record_ids is no longer supported. Use ignore_fields if you want to prevent the id from being serialized."; end
      if cm.hash_key_access == :indifferent; raise "CONFIG PARSE ERROR: indifferent hash_key_access is not supported for performance reasons. Use either :string or :symbol, the default."; end
      if cm.default_mapping_scope != nil; raise "CONFIG PARSE ERROR: default_mapping_scope is not supported globally. Please log a feature request if you need it, or use switch to the new config syntax which supports per-model defaults."; end
      if cm.use_ruby_date_time == true; raise "CONFIG PARSE ERROR: use_ruby_date_time is not supported by RocketAMF. Please log a feature request if you need it."; end
      if pm.scaffolding == true; raise "CONFIG PARSE ERROR: scaffolding is not supported. Please log a feature request if you need it."; end

      # Populate ClassMappings configs from legacy config
      @ignore_fields = cm.ignore_fields unless cm.ignore_fields.nil?
      @translate_case = cm.translate_case if cm.translate_case == true
      @hash_key_access = cm.hash_key_access unless cm.hash_key_access.nil?
      @use_array_collection = cm.use_array_collection if cm.use_array_collection == true
      @check_for_associations = cm.check_for_associations if cm.check_for_associations == false
      mapset = class_mapper.mappings
      (cm.mappings || []).each do |legacy_mapping|
        mapping = {}
        if legacy_mapping[:type] == 'active_resource'
          raise "CONFIG PARSE ERROR: active_resource mapping type is not supported. Please log a feature request or stop using it."
        end

        # Extract unscoped settings
        mapping[:as] = legacy_mapping[:actionscript]
        mapping[:ruby] = legacy_mapping[:ruby]
        mapping[:methods] = legacy_mapping[:methods] unless legacy_mapping[:methods].nil?
        mapping[:ignore_fields] = legacy_mapping[:ignore_fields] unless legacy_mapping[:ignore_fields].nil?

        # Process possibly scoped settings
        attrs = legacy_mapping[:attributes]
        assoc = legacy_mapping[:associations]
        if attrs.is_a?(Hash) || assoc.is_a?(Hash)
          # Extract scopes
          scopes = []
          scopes += attrs.keys if attrs.is_a?(Hash)
          scopes += assoc.keys if assoc.is_a?(Hash)

          # Build settings for scopes
          scopes.each do |scope|
            scoped = mapping.dup
            scoped[:scope] = scope.to_sym
            scoped[:only] = attrs.is_a?(Hash) ? attrs[scope] : attrs
            scoped.delete(:only) if scoped[:only].nil?
            scoped[:include] = assoc.is_a?(Hash) ? assoc[scope] : assoc
            scoped.delete(:include) if scoped[:include].nil?
            mapset.map scoped
          end
        else
          # No scoping
          mapping[:only] = attrs unless attrs.nil?
          mapping[:include] = assoc unless assoc.nil?
          mapset.map mapping
        end
      end

      # Populate ParameterMapping configs from legacy config
      @populate_params_hash = pm.always_add_to_params if pm.always_add_to_params == false
      (pm.mappings || []).each do |m|
        params = []
        m[:params].each do |k, v|
          unless v =~ /\[(\d+)\]/
            raise "CONFIG PARSE ERROR: parameter mappings are no longer evalled - '#{v}' must match [DIGITS]. Please log a feature request if you need this."
          end
          params[$1.to_i] = k
        end
        self.map_params m[:controller], m[:action], params
      end

      # Reset sandbox
      cm.reset
      pm.reset

      self
    end
  end

  module LegacySandbox #:nodoc:
    module RubyAMF #:nodoc:
      module ClassMappings #:nodoc:
        class << self
          attr_accessor :ignore_fields, :translate_case, :force_active_record_ids, :hash_key_access,
                        :assume_types, :default_mapping_scope, :use_ruby_date_time, :use_array_collection,
                        :check_for_associations, :mappings

          def register mapping
            @mappings ||= []
            @mappings << mapping
          end

          def reset
            methods.each do |m|
              send(m, nil) if m =~ /[\w_]+=/
            end
          end
        end
      end

      module ParameterMappings #:nodoc:
        class << self
          attr_accessor :always_add_to_params, :scaffolding, :mappings

          def register mapping
            @mappings ||= []
            @mappings << mapping
          end

          def reset
            methods.each do |m|
              send(m, nil) if m =~ /[\w_]+=/
            end
          end
        end
      end
    end
  end
end