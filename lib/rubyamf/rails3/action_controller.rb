# Hook up rendering
ActionController::Renderers.add :amf do |amf, options|
  @amf_response = amf
  self.content_type ||= Mime::AMF
  self.response_body = " "
end