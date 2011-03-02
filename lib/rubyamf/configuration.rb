module RubyAMF
  class Configuration
    attr_accessor :translate_case
    attr_accessor :gateway_path
    attr_accessor :auto_class_mapping
    attr_accessor :use_array_collection
    attr_accessor :preload_models

    def initialize
      @translate_case = false
      @gateway_path = "/rubyamf/gateway"
      @auto_class_mapping = false
      @use_array_collection = false
      @preload_models = []
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

    def propagate
      cm = RubyAMF::ClassMapper
      [:translate_case, :auto_class_mapping, :use_array_collection].each do |prop|
        if RubyAMF::ClassMapper.respond_to?("#{prop}=")
          RubyAMF::ClassMapper.send("#{prop}=", self.send(prop))
        end
      end
    end
  end
end