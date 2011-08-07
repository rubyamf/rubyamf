# Make sure ActiveSupport::TimeWithZone serializes correctly
class ActiveSupport::TimeWithZone
  def encode_amf ser
    ser.serialize ser.version, self.to_datetime
  end
end