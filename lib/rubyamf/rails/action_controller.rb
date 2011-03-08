require 'action_controller'

# Hook up MIME type
Mime::Type.register RubyAMF::MIME_TYPE, :amf

# Add common functionality
class ActionController::Base
  protected
  attr_reader :amf_response
end