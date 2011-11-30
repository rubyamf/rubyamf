describe RubyAMF::Rails::RequestProcessor do
  before :all do
    class AmfTestController < ActionController::Base
      def self._routes
        @_routes ||= ActionDispatch::Routing::RouteSet.new
      end

      def simple_test
        render :amf => "success"
      end

      def is_amf_test
        render :amf => is_amf?
      end

      def params_test
        render :amf => params
      end

      def scope_test
        render :amf => {:prop_a => "asdf"}, :mapping_scope => :test_scope
      end

      def raise_test
        raise "exception raised"
      end

      def fault_test
        render :amf => FaultObject.new("exception raised")
      end
    end
  end

  before :each do
    @mock_next = mock("Middleware")
    @app = RubyAMF::Rails::RequestProcessor.new(@mock_next)
    @conf = RubyAMF.configuration = RubyAMF::Configuration.new
  end

  it "should pass through if not AMF" do
    env = Rack::MockRequest.env_for('/amf')
    @mock_next.should_receive(:call).and_return("success")
    @app.call(env).should == "success"
  end

  it "should call proper controller" do
    env = RubyAMF::Test.create_call 3, "AmfTestController.simple_test"
    @app.call(env)
    env['rubyamf.response'].result.should == "success"
  end

  it "should underscore the method name if it can't find it normally" do
    env = RubyAMF::Test.create_call 3, "AmfTestController.simpleTest"
    @app.call(env)
    env['rubyamf.response'].result.should == "success"
  end

  it "should should support is_amf? in controller" do
    env = RubyAMF::Test.create_call 3, "AmfTestController.is_amf_test"
    @app.call(env)
    env['rubyamf.response'].result.should == true
  end

  it "should return an exception if the controller doesn't exist" do
    env = RubyAMF::Test.create_call 3, "Kernel.exec", "puts 'Muhahaha!'"
    @app.call(env)
    err = env['rubyamf.response'].messages[0].data
    err.should be_a(RocketAMF::Values::ErrorMessage)
    err.faultString.should == "Service KernelController does not exist"
  end

  it "should return an exception if the controller doesn't respond to the action" do
    env = RubyAMF::Test.create_call 3, "AmfTestController.non_existant"
    @app.call(env)
    err = env['rubyamf.response'].messages[0].data
    err.should be_a(RocketAMF::Values::ErrorMessage)
    err.faultString.should == "Service AmfTestController does not respond to non_existant"
  end

  it "shouldn't populate params hash if disabled" do
    @conf.populate_params_hash = false
    env = RubyAMF::Test.create_call 3, "AmfTestController.params_test", 1, 2, 3
    @app.call(env)
    params = env['rubyamf.response'].result
    ["action", "controller"].each {|k| params.delete(k)} # Certain versions of rails 2.X don't remove them
    params.should == {}
  end

  it "should map parameters if configured" do
    @conf.map_params "AmfTestController", "params_test", [:param_1, :param_2, :param_3]
    env = RubyAMF::Test.create_call 3, "AmfTestController.params_test", "asdf", "fdsa", 5
    @app.call(env)
    params = env['rubyamf.response'].result
    params[1].should == "fdsa"
    params[:param_1].should == "asdf"
  end

  it "should save mapping scope if rendered with one" do
    env = RubyAMF::Test.create_call 3, "AmfTestController.scope_test"
    @app.call(env)
    env['rubyamf.response'].mapping_scope.should == :test_scope
  end

  it "should catch and handle raised exceptions" do
    env = RubyAMF::Test.create_call 3, "AmfTestController.raise_test"
    @app.call(env)
    err = env['rubyamf.response'].messages[0].data
    err.should be_a(RocketAMF::Values::ErrorMessage)
    err.faultString.should == "exception raised"
  end

  it "should catch and handle returned FaultObjects" do
    env = RubyAMF::Test.create_call 3, "AmfTestController.fault_test"
    @app.call(env)
    err = env['rubyamf.response'].messages[0].data
    err.should be_a(RocketAMF::Values::ErrorMessage)
    err.faultString.should == "exception raised"
  end
end