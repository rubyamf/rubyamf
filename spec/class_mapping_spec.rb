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