module RubyAMF
  class RequestProcessor
    def initialize app
      @app = app
    end

    # Processes the AMF request and forwards the method calls to the corresponding
    # rails controllers. No middleware beyond the request processor will receive
    # anything if the request is a handleable AMF request.
    def call env
      return @app.call(env) unless env['rubyamf.response']

      # Handle each method call
      req = env['rubyamf.request']
      res = env['rubyamf.response']
      res.each_method_call req do |method, args|
        begin
          ret = handle_method method, args, env
          raise ret if ret.is_a?(Exception) # If they return FaultObject like you could in rubyamf_plugin
          ret
        rescue Exception => e
          # Log and re-raise exception
          RubyAMF.logger.log_error(e)
          e.set_backtrace([]) # So that RocketAMF doesn't send back the full backtrace
          raise e
        end
      end
    end

    def handle_method method, args, env
      raise "Cannot handle method: #{method}"
    end
  end
end