module RubyAMF
  class Fault < ::Exception #:nodoc:
  end
end

# Convenience object carried over from rubyamf_plugin, it can be returned for
# AMF instead of raising an exception.
#
# Example:
#
#   render :amf => FaultObject.new("No users to get")
class FaultObject
  def self.new *args, &block
    if args.length == 2
      raise "payload for FaultObject is no longer available - if you need it you will need to create a custom class to contain your payload"
    end
    message = args.length > 0 ? args[0] : ''

    begin
      raise RubyAMF::Fault.new(message) 
    rescue Exception => e
      # Fix backtrace
      b = e.backtrace
      b.shift
      e.set_backtrace(b)

      # Return new fault object
      return e
    end
  end
end