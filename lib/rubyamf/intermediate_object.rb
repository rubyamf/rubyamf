module RubyAMF
  class IntermediateObject
    attr_accessor :object, :options

    def initialize object, options
      @object = object
      @options = options
    end

    def rubyamf_hash
      @object.rubyamf_hash @options
    end
  end
end