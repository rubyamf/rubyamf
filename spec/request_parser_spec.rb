require 'spec_helper.rb'

describe RubyAMF::RequestParser do
  before :each do
    @mock_next = mock("Middleware")
    @app = RubyAMF::RequestParser.new(@mock_next)
    @conf = RubyAMF.configuration = RubyAMF::Configuration.new
    @conf.gateway_path = "/amf"
    @env = {
      'PATH_INFO' => '/amf',
      'CONTENT_TYPE' => RubyAMF::MIME_TYPE,
      'rack.input' => StringIO.new(RocketAMF::Envelope.new.to_s)
    }
  end

  it "should only handle requests with proper content type" do
    @app.should_handle?(@env).should be_true
    @env['CONTENT_TYPE'] = 'text/html'
    @app.should_handle?(@env).should be_false
  end

  it "should only handle requests with proper gateway path" do
    @app.should_handle?(@env).should be_true
    @env['PATH_INFO'] = "/invalid"
    @app.should_handle?(@env).should be_false
  end

  it "should pass through requests that aren't AMF" do
    @mock_next.should_receive(:call).and_return("success")
    @app.stub!(:should_handle?).and_return(false)
    @app.call(@env).should == "success"
  end

  it "should serialize to AMF if the response is constructed" do
    @mock_next.stub!(:call) {|env| env['rubyamf.response'].should_receive('constructed?').and_return(true)}
    RubyAMF.should_receive('logger').and_return(Logger.new(nil)) # Silence logging
    response = @app.call(@env)
    response[1]["Content-Type"].should == RubyAMF::MIME_TYPE
  end
end