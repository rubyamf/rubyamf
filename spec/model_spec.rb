require "spec_helper.rb"

# Include in ActiveRecord because rails bootstrap not triggered in specs
require "rubyamf/rails/model"
ActiveRecord::Base.send(:include, RubyAMF::Rails::Model)

describe RubyAMF::Model do
  before :all do
    class SimpleModelTestObject
      include RubyAMF::Model
      attr_accessor :prop_a, :prop_b
      def initialize
        @prop_a = "asdf"
        @prop_b = "fdsa"
      end
    end

    class ModelTestObject
      include RubyAMF::Model
      attr_accessor :attributes, :settable_method
      def initialize
        @attributes = {"prop_a" => "asdf", "prop_b" => "fdsa"}
      end
      def a_method
        "result"
      end
    end

    p = Parent.create :name => "parent"
    p.children.create :name => "child 1"
    p.children.create :name => "child 2"
    p.home = Home.create :address => "1234 Main St."
  end

  before :each do
    RubyAMF::ClassMapper.reset
    RubyAMF.configuration = RubyAMF::Configuration.new
  end

  describe 'configuration' do
    it "should map ruby class to flash class" do
      ModelTestObject.module_eval do
        as_class "as"
        actionscript_class "actionscript"
        flash_class "flash"
      end
      m = RubyAMF::ClassMapper.mappings
      m.get_as_class_name("ModelTestObject").should == "flash"
      m.get_ruby_class_name("flash").should == "ModelTestObject"
    end

    it "should save serialization configs to class mapper" do
      ModelTestObject.module_eval do
        as_class "com.test.ASClass"
        map_amf :only => "prop_a"
        map_amf :testing, :only => "prop_b"
        map_amf :default_scope => :asdf, :only => "prop_c"
      end
      m = RubyAMF::ClassMapper.mappings
      m.get_as_class_name("ModelTestObject").should == "com.test.ASClass"
      m.get_ruby_class_name("com.test.ASClass").should == "ModelTestObject"
      m.serialization_config("ModelTestObject", :default).should == {:only => "prop_a"}
      m.serialization_config("ModelTestObject", :testing).should == {:only => "prop_b"}
      m.serialization_config("ModelTestObject", :asdf).should == {:only => "prop_c"}
    end

    it "should work with RocketAMF class mapper" do
      # Swap out class mapper
      old_mapper = RubyAMF.send(:remove_const, :ClassMapper)
      RubyAMF.const_set(:ClassMapper, RocketAMF::ClassMapping)

      # Test it
      ModelTestObject.module_eval do
        as_class "com.test.ASClass"
        map_amf :only => "prop_a"
        map_amf :testing, :only => "prop_b"
        map_amf :default_scope => :asdf, :only => "prop_c"
      end
      m = RubyAMF::ClassMapper.mappings
      m.get_as_class_name("ModelTestObject").should == "com.test.ASClass"
      m.get_ruby_class_name("com.test.ASClass").should == "ModelTestObject"

      # Swap old class mapper back in
      RubyAMF.send(:remove_const, :ClassMapper)
      RubyAMF.const_set(:ClassMapper, old_mapper)
    end
  end

  describe 'deserialization' do
    it "should populate simple object properly from deserialization" do
      t = SimpleModelTestObject.allocate
      t.rubyamf_init({:prop_a => "seta", :prop_b => "setb"})
      t.prop_a.should == "seta"
      t.prop_b.should == "setb"
    end

    it "should populate fully-conforming object properly from deserialization" do
      t = ModelTestObject.allocate
      t.rubyamf_init({"prop_a" => "seta"}, {"prop_b" => "setb"}) # classmapper would pass symbolic keys - oh well?
      t.attributes.should == {"prop_a" => "seta", "prop_b" => "setb"}
    end

    it "should call setters for non-attributes" do
      t = ModelTestObject.allocate
      t.rubyamf_init({"prop_a" => "seta", "settable_method" => "meth"})
      t.attributes.should == {"prop_a" => "seta"}
      t.settable_method.should == "meth"
    end
  end

  describe 'serialization' do
    it "should return an IntermediateObject when to_amf is called" do
      t = ModelTestObject.new
      obj = t.to_amf({:only => "prop_a"})
      obj.should be_a(RubyAMF::IntermediateObject)
      obj.object.should == t
      obj.options.should == {:only => "prop_a"}
    end

    it "should convert simple object to serializable hash" do
      t = SimpleModelTestObject.new
      t.rubyamf_hash.should == {"prop_a" => "asdf", "prop_b" => "fdsa"}
      t.rubyamf_hash(:only => "prop_a").should == {"prop_a" => "asdf"}
      t.rubyamf_hash(:except => ["prop_a"]).should == {"prop_b" => "fdsa"}
    end

    it "should convert fully-conforming object to serializable hash" do
      t = ModelTestObject.new
      t.rubyamf_hash.should == t.attributes
      t.rubyamf_hash(:only => "prop_a").should == {"prop_a" => "asdf"}
      t.rubyamf_hash(:except => ["prop_a"]).should == {"prop_b" => "fdsa"}
      t.rubyamf_hash(:methods => :a_method).should == {"prop_a" => "asdf", "prop_b" => "fdsa", "a_method" => "result"}
    end

    it "should properly process generic includes" do
      t = ModelTestObject.new
      t.should_receive(:courses).and_return([ModelTestObject.new])
      h = t.rubyamf_hash(:except => "prop_a", :include => :courses)
      h.keys.sort.should == ["courses", "prop_b"]
      h["prop_b"].should == "fdsa"
      h["courses"].length.should == 1
      h["courses"][0].class.should == ModelTestObject
    end

    it "should convert configured includes to IntermediateObjects" do
      t = ModelTestObject.new
      t.should_receive(:courses).and_return([ModelTestObject.new])
      h = t.rubyamf_hash(:except => "prop_a", :include => {:courses => {:except => "prop_b"}})
      h.keys.sort.should == ["courses", "prop_b"]
      h["prop_b"].should == "fdsa"
      h["courses"].length.should == 1
      h["courses"][0].options.should == {:except => "prop_b"}
    end
  end

  # Need to run these tests against rails 2.3, 3.0, and 3.1
  describe 'ActiveRecord' do
    describe 'deserialization' do

      it "should create new records if no id given" do
        c = Child.allocate
        c.rubyamf_init({:name => "Foo Bar"})
        c.name.should == "Foo Bar"
        c.new_record?.should == true
        c.changed.should == ["name"]
      end

      it "should create new records if id is 'empty'" do
        c = Child.allocate
        c.rubyamf_init({:id => 0, :name => "Foo Bar"})
        c.name.should == "Foo Bar"
        c.new_record?.should == true
        c.changed.should == ["name"]

        c = Child.allocate
        c.rubyamf_init({:id => nil, :name => "Foo Bar"})
        c.name.should == "Foo Bar"
        c.new_record?.should == true
        c.changed.should == ["name"]
      end

      it "should determine whether a record is new if composite PK" do
        # Create composite child in DB
        c = CompositeChild.new
        c.id = [10, "blah"]
        c.save

        # Check it
        c = CompositeChild.allocate
        c.rubyamf_init({:id => 10, :name => "blah"})
        c.id.should == [10, "blah"]
        c.new_record?.should == false
        c.changed.should == []
      end

      it "should properly initialize 'existing' objects" do
        c = Child.allocate
        c.rubyamf_init({:id => 5, :name => "Bar Foo"})
        c.id.should == 5
        c.name.should == "Bar Foo"
        c.new_record?.should == false
        c.changed.should == ["name"]
      end

      it "should properly initialize STI objects"

      context "associations" do
        let(:p) { Parent.allocate }
        let(:c) { Child.allocate }
        let(:p_with_associations) { Parent.allocate }

        def create_deserialized_parent_with_associations children=nil, home=nil, save_parent=true
          p_with_associations.rubyamf_init({:id => p.id, :name => "parent", :children => children, :home => home})
          p_with_associations.save if save_parent
        end

        before :each do
          c.rubyamf_init({:name => "Foo Bar"})
          p.rubyamf_init({:name => "parent", :children => [c]})
          p.children.length.should == 1
          p.save
        end

        it "should deserialize associations" do
          p.children[0].parent_id.should == p.id
        end

        it "should deserialize and not clear empty associations" do
          create_deserialized_parent_with_associations []
          p_with_associations.children(true).length.should == 1
        end

        it "should ignore nil associations" do
          create_deserialized_parent_with_associations nil
          p_with_associations.children(true).length.should == 1
        end

        it "should deserialize and not automatically save associations" do
          c2 = Child.allocate
          c2.rubyamf_init({:name => "Foo Bars"})
          h = Home.allocate
          h.rubyamf_init(:address => "1234 Here")
          create_deserialized_parent_with_associations [c2], h, false
          c2.should be_new_record
          h.should be_new_record
          p_with_associations.save
          c2.should_not be_new_record
          h.should_not be_new_record
        end
      end
    end

    describe 'serialization' do
      it "should support serializing associations" do
        h = Parent.first.rubyamf_hash(:include => [:children])
        h["children"].length.should == 2
      end

      it "should support serializing associations with configurations" do
        h = Parent.first.rubyamf_hash(:include => {:children => {:only => "name"}})
        h["children"].length.should == 2
      end

      it "should support automatically including loaded relations without belongs_to" do
        # No associations pre-loaded
        p = Parent.first
        p.rubyamf_hash.should == {"id" => 1, "name" => "parent"}

        # Force associations to load
        p.children.to_a
        p.home

        # Associations should be in hash
        h = p.rubyamf_hash
        h["children"].length.should == 2
        h["children"][0].rubyamf_hash.should == {"id" => 1, "name" => "child 1", "parent_id" => 1}
        h["home"].should == p.home
      end
    end
  end
end
