require 'logger'

module RubyAMF
  class RequestParser
    def initialize app, gateway_path, logger=nil
      @app = app
      @gateway_path = gateway_path
      @logger = logger || Logger.new(STDERR)
    end

    # If the content type is AMF and the path matches the configured gateway path,
    # it parses the request, creates a response object, and forwards the call
    # to the next middleware. If the amf response is constructed, then it serializes
    # the response and returns it as the response.
    def call env
      return @app.call(env) unless should_handle?(env)

      # Wrap request and response
      env['rack.input'].rewind
      env['rubyamf.request'] = RocketAMF::Envelope.new.populate_from_stream(env['rack.input'].read)
      env['rubyamf.response'] = RocketAMF::Envelope.new

      # Pass up the chain to the request processor, or whatever is layered in between
      result = @app.call(env)

      # Calculate length and return response
      if env['rubyamf.response'].constructed?
        @logger.info "Sending back AMF"
        response = env['rubyamf.response'].to_s
        return [200, {"Content-Type" => RubyAMF::MIME_TYPE, 'Content-Length' => response.length.to_s}, [response]]
      else
        return result
      end
    end

    # Check if we should handle it based on the environment
    def should_handle? env
      return false unless env['CONTENT_TYPE'] == RubyAMF::MIME_TYPE
      return false unless @gateway_path == env['PATH_INFO']
      true
    end
  end
end