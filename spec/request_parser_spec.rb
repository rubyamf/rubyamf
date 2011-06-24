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

  it "should send HTML page if enabled for gateway requests" do
    @env['CONTENT_TYPE'] = 'text/html'
    @app.call(@env)[2].first.should =~ /html/
  end

  it "should send image if HTML page enabled" do
    @env['PATH_INFO'] = "/amf/gateway.png"
    @app.call(@env)[1]['Content-Type'].should == 'image/png'
  end

  it "should not send HTML page if not enabled" do
    @conf.show_html_gateway = false
    @env['CONTENT_TYPE'] = 'text/html'
    @mock_next.should_receive(:call).and_return("success")
    @app.call(@env).should == "success"
  end

  it "should pass through requests that aren't AMF" do
    @env['PATH_INFO'] = "/invalid"
    @mock_next.should_receive(:call).and_return("success")
    @app.call(@env).should == "success"
  end

  it "should serialize to AMF if the response is constructed" do
    @mock_next.stub!(:call) {|env| env['rubyamf.response'].should_receive('constructed?').and_return(true)}
    RubyAMF.should_receive('logger').and_return(Logger.new(nil)) # Silence logging
    response = @app.call(@env)
    response[1]["Content-Type"].should == RubyAMF::MIME_TYPE
  end
end