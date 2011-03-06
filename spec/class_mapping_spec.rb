require "spec_helper.rb"

describe RubyAMF::MappingSet do
  before :each do
    @set = RubyAMF::MappingSet.new
  end

  it "should have default mappings" do
    @set.get_as_class_name('RocketAMF::Values::RemotingMessage').should == 'flex.messaging.messages.RemotingMessage'
    @set.get_ruby_class_name('flex.messaging.messages.RemotingMessage').should == 'RocketAMF::Values::RemotingMessage'
  end

  it "should store serialization attributes by scope" do
    @set.map :as => 'A', :ruby => 'R', :default_scope => :scope_a, :except => ['a']
    @set.map :as => 'A', :ruby => 'R', :scope => :scope_b, :except => ['b']

    @set.serialization_config('R').should == {:except => ['a']}
    @set.serialization_config('R', :scope_b).should == {:except => ['b']}
  end

  it "should assume default scope if configuring attributes" do
    @set.map :as => 'A', :ruby => 'R', :except => ['a']

    @set.serialization_config('R').should == {:except => ['a']}
  end

  it "should update scopes on change" do
    @set.map :as => 'A', :ruby => 'R', :scope => :default, :only => ['a']
    @set.map :as => 'A', :ruby => 'R', :scope => :default, :except => ['b']

    @set.serialization_config('R').should == {:except => ['b']}
  end
end

class UnmappedClass; end
class MappingTestClass; end

describe RubyAMF::ClassMapping do
  before :each do
    RubyAMF::ClassMapping.reset
    @set = RubyAMF::ClassMapping.mappings
    @mapper = RubyAMF::ClassMapping.new
  end

  it "should auto-map class on deserialization correctly" do
    @mapper.instance_variable_set("@auto_class_mapping", true)
    as_name = "com.test.UnmappedClass"
    @set.get_ruby_class_name(as_name).should == nil
    obj = @mapper.get_ruby_obj as_name
    obj.class.should == UnmappedClass
    @set.get_ruby_class_name(as_name).should == "UnmappedClass"
  end

  it "should auto-map class on serialization correctly" do
    @mapper.instance_variable_set("@auto_class_mapping", true)
    name = "UnmappedClass"
    @set.get_as_class_name(name).should == nil
    @mapper.get_as_class_name(UnmappedClass.new).should == name
    @set.get_as_class_name(name).should == name
  end

  it "should translate property case on deserialization correctly" do
    @mapper.instance_variable_set("@translate_case", true)
    props = {:aProperty => "asdf", :aMoreComplexProperty => "asdf"}
    dynamic_props = {:aDynamicProperty => "fdsa"}
    obj = RocketAMF::Values::TypedHash.new("")
    @mapper.populate_ruby_obj obj, props, dynamic_props
    obj.should == {:a_property => "asdf", :a_more_complex_property => "asdf", :a_dynamic_property => "fdsa"}
  end

  it "should translate property case on serialization correctly" do
    @mapper.instance_variable_set("@translate_case", true)
    obj = {"a_dynamic_property" => "asdf"}
    props = @mapper.props_for_serialization(obj)
    props.should == {"aDynamicProperty" => "asdf"}
  end

  it "should allow setting hash key type to string" do
    @mapper.instance_variable_set("@hash_key_access", :string)
    props = {:asdf => "asdf", :fdsa => "fdsa"}
    obj = RocketAMF::Values::TypedHash.new("")
    @mapper.populate_ruby_obj obj, props
    obj.should == {"asdf" => "asdf", "fdsa" => "fdsa"}
  end

  it "should return correct class name for IntermediateObject" do
    obj = RubyAMF::IntermediateObject.new(MappingTestClass.new, {})
    @set.map :as => "MappingTestClass", :ruby => "MappingTestClass"
    @mapper.get_as_class_name(obj).should == "MappingTestClass"
  end

  it "should extract properties correctly for IntermediateObject" do
    obj = RubyAMF::IntermediateObject.new(MappingTestClass.new, {:only => "asdf"})
    obj.object.should_receive(:rubyamf_hash).with(obj.options).and_return({"asdf" => "fdsa"})
    props = @mapper.props_for_serialization(obj)
    props.should == {"asdf" => "fdsa"}
  end

  it "should properly extract properties for mapped class" do
    obj = MappingTestClass.new
    @set.map :as => "MappingTestClass", :ruby => "MappingTestClass", :only => "asdf"
    obj.should_receive(:rubyamf_hash).with({:only => "asdf"}).and_return({"asdf" => "fdsa"})
    props = @mapper.props_for_serialization(obj)
    props.should == {"asdf" => "fdsa"}
  end
end