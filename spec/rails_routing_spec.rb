require "spec_helper.rb"
require "rubyamf/rails/routing"

describe RubyAMF::Rails::Routing do
  include RubyAMF::Rails::Routing
  def test_map *args
    map_amf *args
    @mappings = RubyAMF.configuration.param_mappings
    if @mappings.size == 1
      @controller, @action = @mappings.keys[0].split("#")
      @params = @mappings.values[0]
    end
  end

  before :each do
    RubyAMF.configuration = RubyAMF::Configuration.new # Reset configuration
  end

  it "should support string style call" do
    test_map("user#show", [:asdf, :fdsa])
    @controller.should == "UserController"
    @action.should == "show"
    @params.should == [:asdf, :fdsa]
  end

  it "should support option style call" do
    test_map(:controller => "user", :action => "show", :params => [:asdf, :fdsa])
    @controller.should == "UserController"
    @action.should == "show"
    @params.should == [:asdf, :fdsa]
  end

  it "should not camelize controller name if already camelized" do
    test_map(:controller => "AdminController", :action => "login", :params => [])
    @controller.should == "AdminController"
  end

  it "should support module-style namespace for non-rails" do
    test_map("user#show", [], {:namespace => "NamespaceComplex::Nested"})
    @controller.should == "NamespaceComplex::Nested::UserController"
  end

  it "should support multiple action mapping" do
    test_map(:user, "show" => [:asdf, :fdsa], :login => [:fdsa, :asdf])
    @mappings["UserController#show"].should == [:asdf, :fdsa]
    @mappings["UserController#login"].should == [:fdsa, :asdf]
  end

  describe "Rails 2" do
    it "should recognize namespace with string style call" do
      test_map(:controller => "user", :action => "show", :params => [], :namespace => "namespace_complex/nested")
      @controller.should == "NamespaceComplex::Nested::UserController"
    end

    it "should recognize namespace with option style call" do
      test_map("user#show", [], {:namespace => "namespace/nested"})
      @controller.should == "Namespace::Nested::UserController"
    end

    it "should recognize namespace with multiple action style call" do
      test_map(:user, "show" => [:asdf, :fdsa], :login => [:fdsa, :asdf], :namespace => "namespace/nested")
      @mappings.size.should == 2
      @mappings["Namespace::Nested::UserController#show"].should == [:asdf, :fdsa]
      @mappings["Namespace::Nested::UserController#login"].should == [:fdsa, :asdf]
    end
  end

  describe "Rails 3" do
    it "should recognize namespace" do
      @scope = {:module => "namespace/nested"}
      test_map("user#show", [])
      @controller.should == "Namespace::Nested::UserController"
    end
  end
end