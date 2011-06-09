module RubyAMF
  # IntermediateObject packages an object with its requested serialization options.
  # This allows the pre-configured serialization configuration to be overridden
  # as needed. They are automatically created by <tt>to_amf</tt> and should not
  # be generated manually.
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