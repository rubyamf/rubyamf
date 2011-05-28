require 'app/configuration'
module RubyAMF
  module Configuration
    ClassMappings.ignore_fields = ['changed']
    ClassMappings.translate_case = true
    ClassMappings.hash_key_access = :string
    ClassMappings.assume_types = true
    ClassMappings.use_array_collection = true
    ClassMappings.check_for_associations = false
    ParameterMappings.always_add_to_params = false

    ClassMappings.register(:actionscript => 'Blank', :ruby => 'Blank', :type => 'active_record')
    ClassMappings.register(:actionscript => 'Attribute', :ruby => 'Attribute', :type => 'active_record', :attributes => ["prop_a", "prop_b"])
    ClassMappings.register(:actionscript => 'Association', :ruby => 'Association', :type => 'active_record', :associations=> ["assoc_a", "assoc_b"])
    ClassMappings.register(:actionscript => 'Both', :ruby => 'Both', :type => 'active_record', :attributes => ["prop_a", "prop_b"], :associations=> ["assoc_a", "assoc_b"])
    ClassMappings.register(:actionscript => 'Method', :ruby => 'Method', :methods => ["meth_a"])
    ClassMappings.register(:actionscript => 'Scoped1', :ruby => 'Scoped1', :attributes => {"scope_1" => ["prop_a", "prop_b"], "scope_2" => ["prop_a"]})
    ClassMappings.register(:actionscript => 'Scoped2', :ruby => 'Scoped2', :associations => {:scope_1 => ["assoc_a", "assoc_b"], :scope_2 => ["assoc_a"]})
    ClassMappings.register(:actionscript => 'Scoped3', :ruby => 'Scoped3', :attributes => {"scope_1" => ["prop_a", "prop_b"], "scope_2" => ["prop_a"]}, :associations => ["assoc_a", "assoc_b"])
    ClassMappings.register(:actionscript => 'Scoped4', :ruby => 'Scoped4', :attributes => {"scope_1" => ["prop_a", "prop_b"], "scope_2" => ["prop_a"]}, :associations => {"scope_1" => ["assoc_a", "assoc_b"], "scope_3" => ["assoc_a"]})

    ParameterMappings.register(:controller => :Controller, :action => :action, :params => {:param_1 => "[0]", :param_2 => "[1]", :param_4 => "[3]"})
  end
end