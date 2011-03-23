module RubyAMF
  class Configuration
    # Rack options
    attr_accessor :gateway_path

    # Serialization options
    attr_accessor :translate_case, :auto_class_mapping, :use_array_collection, :hash_key_access, :preload_models

    def initialize
      @gateway_path = "/rubyamf/gateway"
      @translate_case = false
      @auto_class_mapping = false
      @use_array_collection = false
      @hash_key_access = :symbol
      @preload_models = []
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