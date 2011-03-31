require 'action_controller'

# Hook up MIME type
Mime::Type.register RubyAMF::MIME_TYPE, :amf

# Add common functionality
class ActionController::Base
  protected
  attr_reader :amf_response, :mapping_scope, :rubyamf_params, :credentials

  def is_amf?
    @is_amf == true
  end
  alias_method :is_amf, :is_amf?
  alias_method :is_rubyamf, :is_amf?
end