require "spec_helper.rb"

class SerTestClass
  include RubyAMF::Serialization
  def attributes
    {"prop_a" => "asdf", "prop_b" => "fdsa"}
  end
  def a_method
    "result"
  end
end

class NonConformingClass
  include RubyAMF::Serialization
end

describe RubyAMF::Serialization do
  before :each do
    RubyAMF::ClassMapper.reset
  end

  it "should map ruby class to flash class" do
    SerTestClass.module_eval do
      as_class "as"
      actionscript_class "actionscript"
      flash_class "flash"
    end
    m = RubyAMF::ClassMapper.mappings
    m.get_as_class_name("SerTestClass").should == "flash"
    m.get_ruby_class_name("flash").should == "SerTestClass"
  end

  it "should save serialization configs to class mapper" do
    SerTestClass.module_eval do
      as_class "com.test.ASClass"
      map_amf :only => "prop_a"
      map_amf :testing, :only => "prop_b"
      map_amf :default_scope => :asdf, :only => "prop_c"
    end
    m = RubyAMF::ClassMapper.mappings
    m.get_as_class_name("SerTestClass").should == "com.test.ASClass"
    m.get_ruby_class_name("com.test.ASClass").should == "SerTestClass"
    m.serialization_config("SerTestClass", :default).should == {:only => "prop_a"}
    m.serialization_config("SerTestClass", :testing).should == {:only => "prop_b"}
    m.serialization_config("SerTestClass", :asdf).should == {:only => "prop_c"}
  end

  it "should convert conforming object to serializable hash" do
    t = SerTestClass.new
    t.rubyamf_hash.should == t.attributes
    t.rubyamf_hash(:only => "prop_a").should == {"prop_a" => "asdf"}
    t.rubyamf_hash(:except => ["prop_a"]).should == {"prop_b" => "fdsa"}
    t.rubyamf_hash(:methods => :a_method).should == {"prop_a" => "asdf", "prop_b" => "fdsa", "a_method" => "result"}
  end

  it "should raise exception if object does not conform" do
    a = NonConformingClass.new
    lambda {
      a.rubyamf_hash
    }.should raise_error
  end
end