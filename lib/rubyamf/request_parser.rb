module RubyAMF
  # RubyAMF uses a two-stage middleware strategy. RequestParser is the first
  # stage, and is responsible for parsing the stream and setting
  # <tt>env ['rubyamf.request']</tt> and <tt>env ['rubyamf.response']</tt> to
  # an instance of RubyAMF::Envelope. If the response envelope is marked as
  # constructed, it will send back the serialized response. The second stage is
  # RubyAMF::Rails::RequestProcessor.
  class RequestParser
    def initialize app
      @app = app
    end

    # Determine how to handle the request and pass off to <tt>handle_amf</tt>,
    # <tt>handle_image</tt>, or <tt>handle_html</tt>. If the <tt>show_html_gateway</tt>
    # config is set to false, it will not serve an HTML page for non-amf requests
    # to the gateway.
    def call env
      # Show HTML gateway page if it's enabled for non-amf requests
      if RubyAMF.configuration.show_html_gateway
        if env['PATH_INFO'] == gateway_image_path
          return handle_image
        elsif env['PATH_INFO'] == gateway_path && env['CONTENT_TYPE'] != RubyAMF::MIME_TYPE
          return handle_html
        end
      end

      # Handle if it's AMF or pass it up the chain
      if env['PATH_INFO'] == gateway_path && env['CONTENT_TYPE'] == RubyAMF::MIME_TYPE
        return handle_amf(env)
      else
        return @app.call(env)
      end
    end

    # It parses the request, creates a response object, and forwards the call
    # to the next middleware. If the amf response is constructed, then it serializes
    # the response and returns it as the response.
    def handle_amf env
      # Wrap request and response
      env['rack.input'].rewind
      begin
        env['rubyamf.request'] = RubyAMF::Envelope.new.populate_from_stream(env['rack.input'].read)
      rescue Exception => e
        RubyAMF.logger.log_error(e)
        msg = "Invalid AMF request"
        return [400, {"Content-Type" => "text/plain", 'Content-Length' => msg.length.to_s}, [msg]]
      end
      env['rubyamf.response'] = RubyAMF::Envelope.new

      # Pass up the chain to the request processor, or whatever is layered in between
      result = @app.call(env)

      # Calculate length and return response
      if env['rubyamf.response'].constructed?
        RubyAMF.logger.info "Sending back AMF"
        response = env['rubyamf.response'].to_s
        return [200, {"Content-Type" => RubyAMF::MIME_TYPE, 'Content-Length' => response.length.to_s}, [response]]
      else
        return result
      end
    end

    # It returns a simple HTML page confirming that the gateway is properly running
    def handle_html
      info_url = "https://github.com/rubyamf/rubyamf"
      html = <<END_OF_HTML
<html>
  <head>
    <title>RubyAMF Gateway</title>
    <style>body{margin:0;padding:0;color:#c8c8c8;background-color:#222222;}</style>
  </head>
  <body>
    <table width="100%" height="100%" align="center" valign="middle">
      <tr><td align="center"><a href="#{info_url}"><img border="0" src="#{gateway_image_path}" /></a></td></tr>
    </table>
  </body>
</html>
END_OF_HTML
      return [200, {'Content-Type' => 'text/html', 'Content-Length' => html.length.to_s}, [html]]
    end

    # Serve rubyamf logo for html page
    def handle_image
      path = File.join(File.dirname(__FILE__), 'gateway.png')
      content = File.read(path)
      size = content.respond_to?(:bytesize) ? content.bytesize : content.size
      return [200, {'Content-Type' => 'image/png', 'Content-Length' => size.to_s}, [content]]
    end

    def gateway_path #:nodoc:
      path = RubyAMF.configuration.gateway_path
      path.end_with?("/") ? path[0...-1] : path
    end

    def gateway_image_path #:nodoc:
      gateway_path + "/gateway.png"
    end
  end
end