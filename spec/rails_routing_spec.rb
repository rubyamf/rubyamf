require "spec_helper.rb"
require "rubyamf/rails/routing"

describe RubyAMF::Rails::Routing do
  include RubyAMF::Rails::Routing
  def test_map *args
    config = mock(RubyAMF::Configuration)
    config.stub!(:map_params).and_return do |c,a,p|
      @controller = c
      @action = a
      @params = p
    end
    RubyAMF.stub!(:configuration).and_return(config)
    map_amf *args
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

  describe "Rails 2" do
    it "should recognize namespace with string style call" do
      test_map(:controller => "user", :action => "show", :params => [], :namespace => "namespace_complex/nested")
      @controller.should == "NamespaceComplex::Nested::UserController"
    end

    it "should recognize namespace with option style call" do
      test_map("user#show", [], {:namespace => "namespace/nested"})
      @controller.should == "Namespace::Nested::UserController"
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