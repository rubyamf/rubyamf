module RubyAMF::Rails
  module Controller
    protected
    attr_reader :amf_response, :mapping_scope, :rubyamf_params, :credentials

    def is_amf?
      @is_amf == true
    end
    alias_method :is_amf, :is_amf?
    alias_method :is_rubyamf, :is_amf?
  end
end