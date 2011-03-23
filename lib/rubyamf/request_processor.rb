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
        handle_method method, args, env
      end
    end

    def handle_method method, args, env
      raise "Cannot handle method: #{method}"
    end
  end
end