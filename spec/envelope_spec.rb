require "spec_helper.rb"

describe RubyAMF::Envelope do
  before :each do
    @envelope = RubyAMF::Envelope.new
    @logger = mock(RubyAMF::Logger)
    @logger.stub!("log_error")
    RubyAMF.configuration = RubyAMF::Configuration.new # Reset configuration
  end

  def create_envelope fixture
    data = File.open(File.dirname(__FILE__) + '/fixtures/' + fixture).read
    data.force_encoding("ASCII-8BIT") if data.respond_to?(:force_encoding)
    RubyAMF::Envelope.new.populate_from_stream(StringIO.new(data))
  end

  it "should raise and handle returned exception objects like RubyAMF::Fault" do
    RubyAMF.should_receive("logger").and_return(@logger)

    res = RubyAMF::Envelope.new
    req = create_envelope('remotingMessage.bin')
    res.each_method_call req do |method, args|
      FaultObject.new('Error in call')
    end

    res.messages.length.should == 1
    res.messages[0].data.should be_a(RocketAMF::Values::ErrorMessage)
    res.messages[0].data.faultString.should == "Error in call"
  end

  it "should clear backtrace from raised exceptions before serialization" do
    RubyAMF.should_receive("logger").and_return(@logger)

    res = RubyAMF::Envelope.new
    req = create_envelope('remotingMessage.bin')
    res.each_method_call req do |method, args|
      raise 'Error in call'
    end

    res.messages.length.should == 1
    res.messages[0].data.should be_a(RocketAMF::Values::ErrorMessage)
    res.messages[0].data.faultDetail.should == ""
  end

  it "should log exceptions in each_method_call handler" do
    e = Exception.new('Error in call')
    @logger.should_receive("log_error").with(e).and_return(nil)
    RubyAMF.should_receive("logger").and_return(@logger)

    res = RubyAMF::Envelope.new
    req = create_envelope('remotingMessage.bin')
    res.each_method_call req do |method, args|
      raise e
    end
  end

  it "should calculate params hash from configuration" do
    RubyAMF.configuration.map_params "c", "a", ["param1", :param2]
    params = @envelope.params_hash "c", "a", ["asdf", "fdsa"]
    params.should == {"param1" => "asdf", "param2" => "fdsa", 0 => "asdf", 1 => "fdsa"}
  end

  it "should respect hash_key_access for params hash" do
    RubyAMF.configuration.hash_key_access = :symbol
    RubyAMF.configuration.map_params "c", "a", ["param1", :param2]
    params = @envelope.params_hash "c", "a", ["asdf", "fdsa"]
    params.should == {:param1 => "asdf", :param2 => "fdsa", 0 => "asdf", 1 => "fdsa"}
  end

  it "should expose credentials set through NetConnection credentials header" do
    req = create_envelope('requestWithOldCredentials.bin')
    req.credentials.should == {'username' => "username", 'password' => "password"}
  end

  it "should expose credentials set through setRemoteCredentials" do
    req = create_envelope('requestWithNewCredentials.bin')
    req.credentials.should == {'username' => "username", 'password' => "password"}
  end

  it "should return empty credentials if unset" do
    req = create_envelope('remotingMessage.bin')
    req.credentials.should == {'username' => nil, 'password' => nil}
  end

  it "should respect hash_key_access config for credentials" do
    RubyAMF.configuration.hash_key_access = :symbol
    req = create_envelope('requestWithOldCredentials.bin')
    req.credentials.should == {:username => "username", :password => "password"}
    req = create_envelope('requestWithNewCredentials.bin')
    req.credentials.should == {:username => "username", :password => "password"}
    req = create_envelope('remotingMessage.bin')
    req.credentials.should == {:username => nil, :password => nil}
  end

  it "should respect translate_case config for credentials" do
    RubyAMF.configuration.translate_case = true
    req = create_envelope('requestWithOldCredentials.bin')
    req.credentials.should == {'username' => "username", 'password' => "password"}
    req = create_envelope('requestWithNewCredentials.bin')
    req.messages[0].data.messageId.should == "CA4F7056-317E-FC0C-BEDA-DFFC8B3AA791"
    req.credentials.should == {'username' => "username", 'password' => "password"}
    req = create_envelope('remotingMessage.bin')
    req.messages[0].data.messageId.should == "FE4AF2BC-DD3C-5470-05D8-9971D51FF89D"
    req.credentials.should == {'username' => nil, 'password' => nil}
  end
end
