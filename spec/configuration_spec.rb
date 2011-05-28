require "spec_helper.rb"

describe RubyAMF::Configuration do
  before :each do
    RubyAMF::ClassMapping.reset
    @conf = RubyAMF::Configuration.new
    @legacy_path = File.dirname(__FILE__) + '/fixtures/rubyamf_config.rb'
  end

  it "should read legacy files without errors" do
    @conf.load_legacy(@legacy_path)
  end

  it "should properly map blank class mapping" do
    @conf.load_legacy(@legacy_path)
    mapset = RubyAMF::ClassMapping.mappings
    mapset.get_ruby_class_name('Blank').should == 'Blank'
    mapset.serialization_config('Blank').should == nil
  end

  it "should properly map attribute setting" do
    @conf.load_legacy(@legacy_path)
    mapset = RubyAMF::ClassMapping.mappings
    mapset.serialization_config('Attribute').should == {:only => ["prop_a", "prop_b"]}
  end

  it "should properly map association setting" do
    @conf.load_legacy(@legacy_path)
    mapset = RubyAMF::ClassMapping.mappings
    mapset.serialization_config('Association').should == {:include => ["assoc_a", "assoc_b"]}
  end

  it "should properly map attribute and association setting" do
    @conf.load_legacy(@legacy_path)
    mapset = RubyAMF::ClassMapping.mappings
    mapset.serialization_config('Both').should == {
      :only => ["prop_a", "prop_b"],
      :include => ["assoc_a", "assoc_b"]
    }
  end

  it "should properly map methods setting" do
    @conf.load_legacy(@legacy_path)
    mapset = RubyAMF::ClassMapping.mappings
    mapset.serialization_config('Method').should == {:methods => ["meth_a"]}
  end

  it "should properly map scoped attributes" do
    @conf.load_legacy(@legacy_path)
    mapset = RubyAMF::ClassMapping.mappings
    mapset.serialization_config('Scoped1', :scope_1).should == {:only => ["prop_a", "prop_b"]}
    mapset.serialization_config('Scoped1', "scope_2").should == {:only => ["prop_a"]}
  end

  it "should properly map scoped associations" do
    @conf.load_legacy(@legacy_path)
    mapset = RubyAMF::ClassMapping.mappings
    mapset.serialization_config('Scoped2', :scope_1).should == {:include => ["assoc_a", "assoc_b"]}
    mapset.serialization_config('Scoped2', :scope_2).should == {:include => ["assoc_a"]}
  end

  it "should properly map partially scoped settings" do
    @conf.load_legacy(@legacy_path)
    mapset = RubyAMF::ClassMapping.mappings
    mapset.serialization_config('Scoped3', :scope_1).should == {
      :only => ["prop_a", "prop_b"],
      :include => ["assoc_a", "assoc_b"]
    }
    mapset.serialization_config('Scoped3', :scope_2).should == {
      :only => ["prop_a"],
      :include => ["assoc_a", "assoc_b"]
    }
  end

  it "should properly map both scoped settings" do
    @conf.load_legacy(@legacy_path)
    mapset = RubyAMF::ClassMapping.mappings
    mapset.serialization_config('Scoped4', :scope_1).should == {
      :only => ["prop_a", "prop_b"],
      :include => ["assoc_a", "assoc_b"]
    }
    mapset.serialization_config('Scoped4', :scope_2).should == {:only => ["prop_a"]}
    mapset.serialization_config('Scoped4', :scope_3).should == {:include => ["assoc_a"]}
  end

  it "should properly store parameter mappings" do
    @conf.load_legacy(@legacy_path)
    @conf.param_mappings["Controller#action"].should == [:param_1, :param_2, nil, :param_4]
  end
end