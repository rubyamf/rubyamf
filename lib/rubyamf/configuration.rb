module RubyAMF
  # RubyAMF configuration container. It can be accessed by calling
  # <tt>RubyAMF.configuration</tt>, or modified in a block like so:
  #
  #   RubyAMF.configure do |config|
  #     config.gateway_path = "/amf"
  #   end
  #
  # === Gateway configuration
  #
  # Gateway configuration includes the gateway path and details about parameter
  # mapping.
  #
  # +gateway_path+::
  #   Default: <tt>"/rubyamf/gateway"</tt>. The URL that responds to AMF requests.
  #   The URL should start with a "/" and not end with a "/".
  #
  # +populate_params_hash+::
  #   Default: <tt>true</tt>. For Rails users, all amf parameters can be accessed
  #   in the controller by calling <tt>rubyamf_params</tt>. If enabled, the amf
  #   parameters are merged into the <tt>params</tt> hash as well.
  #
  # +show_html_gateway+::
  #   Default: <tt>true</tt>. If enabled, non-AMF requests to the gateway url
  #   will result in a simple HTML page being returned.
  #
  # +param_mappings+::
  #    A hash that stores parameter mappings. Should only be modified through
  #    calls to <tt>map_params</tt>
  #
  # === Serialization options
  #
  # RubyAMF provides a wide variety of customization options for serialization
  # to simplify integration.
  #
  # +translate_case+::
  #   Default: <tt>false</tt>. If enabled, properties will be converted to
  #   underscore style on deserialization from actionscript and will be converted
  #   to camelcase on serialization. This allows you to use language appropriate
  #   case style and have RubyAMF automatically care of translation.
  #
  # +auto_class_mapping+::
  #   Default: <tt>false</tt>. If a class mapping for a given ruby or actionscript
  #   class has not been defined, automatically maps it during serialization or
  #   deserialization. Nested ruby or actionscript classes will be automatically
  #   mapped to the class name without the namespace. Example:
  #   <tt>com.rubyamf.User => User</tt> or <tt>RubyAMF::User => User</tt>.
  #
  # +use_array_collection+::
  #   Default: <tt>false</tt>. If enabled, all arrays will be serialized as
  #   <tt>ArrayCollection</tt> objects. You can override this on a per-array
  #   basis by setting <tt>is_array_collection</tt> on the array to <tt>true</tt>
  #   or <tt>false</tt>. (Implementation in RocketAMF)
  #
  # +hash_key_access+::
  #   Default: <tt>:string</tt>. If set to <tt>:symbol</tt>, all deserialized
  #   hashes have the keys as symbols. RocketAMF defaults to strings, so setting
  #   to <tt>:symbol</tt> will reduce performance and possibly open you up to
  #   memory usage attacks.
  #
  # +preload_models+::
  #   If you are using in-model mapping and don't have <tt>auto_class_mapping</tt>
  #   enabled, you may need to force classes to be loaded before mapping takes
  #   effect. Simply include all necessary classes as strings to have RubyAMF
  #   force them to be loaded on initialization.
  #   Example: <tt>config.preload_models = ["User", "Course"]</tt>
  #
  # +check_for_associations+::
  #   Default: <tt>true</tt>. If enabled, associations that have been pre-loaded,
  #   either through :include or simply by being accessed, will be automatically
  #   included during serialization without any additional configuration.
  #
  # +ignore_fields+::
  #   Default: <tt>['created_at', 'created_on', 'updated_at', 'updated_on']</tt>.
  #   A list of all properties that should not be deserialized by default. The
  #   class-level <tt>:ignore_fields</tt> config overrides this.
  class Configuration
    # Gateway options
    attr_accessor :gateway_path, :populate_params_hash, :show_html_gateway
    attr_reader :param_mappings

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
      @hash_key_access = :string
      @preload_models = []
      @check_for_associations = true
      @ignore_fields = ['created_at', 'created_on', 'updated_at', 'updated_on']
    end

    # Maps the given array of named parameters to the arguments for calls to the
    # given controller and action. For Rails users, the prefered method of
    # parameter mapping is through routing (see RubyAMF::Rails::Routing).
    #
    # Example:
    #
    #   config.map_params "UserController", "login", [:session_token, :username, :password]
    #   # params hash => {
    #   #   0 => "asdf", 1 => "user", 2 => "pass",
    #   #   :session_token => "asdf", :username => "user", :password => "pass"
    #   # }
    def map_params controller, action, params
      @param_mappings[controller.to_s+"#"+action.to_s] = params
    end

    # Returns the class mapper class being used
    def class_mapper
      if @class_mapper.nil?
        @class_mapper = RubyAMF::ClassMapping
      end
      @class_mapper
    end

    # Set to the class of any conforming class mapper to use it instead of
    # <tt>RubyAMF::ClassMapping</tt>. If you don't need any of the advanced
    # features offered by the RubyAMF class mapper, you can gain some substantial
    # performance improvements by settings this to
    # <tt>RocketAMF::Ext::FastClassMapping</tt> or <tt>RocketAMF::ClassMapping</tt>
    # for the slower pure-ruby version.
    def class_mapper= klass
      @class_mapper = klass
    end

    # Loads the legacy config file at the given path or tries to locate it by
    # looking for a <tt>rubyamf_config.rb</tt> file in several possible locations.
    # Automatically run by RubyAMF if you are using Rails 2, it should be run
    # before any additional configuration if you are not using Rails 2, as it
    # overrides all previous configuration.
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
      if cm.force_active_record_ids != nil; raise "CONFIG PARSE ERROR: force_active_record_ids is no longer supported. Use <tt>:except</tt> if you want to prevent the id from being serialized."; end
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