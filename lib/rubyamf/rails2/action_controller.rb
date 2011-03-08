class ActionController::Base
  def render_with_amf(options = nil, extra_options ={}, &block)
    if options && options.is_a?(Hash) && options.has_key?(:amf)
      @performed_render = true
      @amf_response = options[:amf]
    else
      render_without_amf(options, extra_options, &block)
    end
  end
  alias_method_chain :render, :amf
end