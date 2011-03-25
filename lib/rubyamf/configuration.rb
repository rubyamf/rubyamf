module RubyAMF
  class Configuration
    # Gateway options
    attr_accessor :gateway_path, :param_mappings, :populate_params_hash

    # Serialization options
    attr_accessor :translate_case, :auto_class_mapping, :use_array_collection,
                  :hash_key_access, :preload_models, :check_for_associations,
                  :ignore_fields

    def initialize
      @gateway_path = "/rubyamf/gateway"
      @param_mappings = {}
      @populate_params_hash = true
      @translate_case = false
      @auto_class_mapping = false
      @use_array_collection = false
      @hash_key_access = :symbol
      @preload_models = []
      @check_for_associations = true
      @ignore_fields = ['created_at', 'created_on', 'updated_at', 'updated_on']
    end

    def map_params options
      @param_mappings[options[:controller]+"#"+options[:action]] = options[:params]
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
  end
end