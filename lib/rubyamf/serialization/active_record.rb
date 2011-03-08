module RubyAMF
  module Serialization
    module ActiveRecord
      def rubyamf_association association
        case self.class.reflect_on_association(association).macro
        when :has_many, :has_and_belongs_to_many
          send(association).to_a
        when :has_one, :belongs_to
          send(association)
        end
      end
    end
  end
end

class ActiveRecord::Base
  include RubyAMF::Serialization
  include RubyAMF::Serialization::ActiveRecord
end