require 'action_controller/railtie'

Mime::Type.register RubyAMF::MIME_TYPE, :amf

module ActionController
  module Renderers
    attr_reader :amf_response

    add :amf do |amf, options|
      @amf_response = amf
      self.content_type ||= Mime::AMF
      self.response_body = " "
    end
  end
end