module RubyAMF::Rails
  # Rails controller extensions to access AMF information.
  module Controller
    protected
    # Contains the parameters hash with named properties if mapped
    attr_reader :rubyamf_params

    # Contains the credentials hash from RubyAMF::Envelope#credentials
    attr_reader :credentials

    # Used internally by RequestProcessor
    attr_reader :amf_response
    # Used internally by RequestProcessor
    attr_reader :mapping_scope

    # Returns whether or not the request is an AMF request
    def is_amf?
      @is_amf == true
    end
    alias_method :is_amf, :is_amf?
    alias_method :is_rubyamf, :is_amf?
  end
end