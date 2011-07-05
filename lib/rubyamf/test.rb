require 'rack/mock'

module RubyAMF
  # Contains helpers to make testing AMF controller testing simple. Rails users
  # can simply use <tt>create_call</tt> and <tt>create_flex_call</tt> to create
  # requests and run them using <tt>dispatch_rails</tt>. Users of other rack-based
  # frameworks will need to handle properly dispatching the request to the right
  # middleware. <tt>create_call_type</tt> creates a rack environment similar to
  # what you would get from RubyAMF::RequestParser, so you can just pass it to
  # whatever your processing middleware is.
  #
  # Rails Example:
  #
  #    env = RubyAMF::Test.create_call 3, "TestController.get_user", 5
  #    res = RubyAMF::Test.dispatch_rails env
  #    res.mapping_scope.should == "testing"
  #    res.result.class.name.should == "User"
  module Test
    class << self
      # Creates a rack environment hash that can be used to dispatch the given
      # call. The environment that is created can be directly dispatched to
      # RubyAMF::Rails::RequestProcessor or your own middleware. The type can either
      # be <tt>:standard</tt> or <tt>:flex</tt>, with the flex type using the same
      # style as <tt>RemoteObject</tt> does.
      def create_call_type type, amf_version, target, *args
        amf_req = RubyAMF::Envelope.new :amf_version => amf_version
        if type == :standard
          amf_req.call target, *args
        elsif type == :flex
          amf_req.call_flex target, *args
        else
          raise "Invalid call type: #{type}"
        end

        env = ::Rack::MockRequest.env_for(RubyAMF.configuration.gateway_path, :method => "post", :input => amf_req.to_s, "CONTENT_TYPE" => RubyAMF::MIME_TYPE)
        env['rubyamf.request'] = amf_req
        env['rubyamf.response'] = RubyAMF::Envelope.new
        env
      end

      # Creates a rack environment for the standard call type
      def create_call amf_version, target, *args
        create_call_type :standard, amf_version, target, *args
      end

      # Creates a rack environment for the flex call type
      def create_flex_call target, *args
        create_call_type :flex, 3, target, *args
      end

      # Dispatches the given rack environment to RubyAMF::Rails::RequestProcessor,
      # which calls the specified controllers. Returns the response RubyAMF::Envelope.
      def dispatch_rails env
        middleware = RubyAMF::Rails::RequestProcessor.new nil
        middleware.call env
        env['rubyamf.response']
      end
    end
  end
end