module RubyAMF
  class Configuration
    # Gateway options
    attr_accessor :gateway_path, :param_mappings

    # Serialization options
    attr_accessor :translate_case, :auto_class_mapping, :use_array_collection, :hash_key_access, :preload_models

    def initialize
      @gateway_path = "/rubyamf/gateway"
      @translate_case = false
      @auto_class_mapping = false
      @use_array_collection = false
      @hash_key_access = :symbol
      @preload_models = []
      @param_mappings = {}
    end

    def map_params options
      @param_mappings[options[:controller]+"#"+options[:action]] = options[:params]
    end

    def class_mapper
      if @class_mapper.nil?
        @class_mapper = RubyAMF::ClassMapping
      end
      @class_mapper.use_array_collection = @use_array_collection # Make sure it gets copied over
      @class_mapper
    end

    def class_mapper= klass
      @class_mapper = klass
    end

    def do_model_preloading
      @preload_models.flatten.each {|m| m.to_s.constantize}
    end
  end
end