module RubyAMF
  module Serialization
    module ActiveRecord
      def rubyamf_hash options=nil
        return super(options) unless RubyAMF.configuration.check_for_associations

        options ||= {}

        # Iterate through assocations and check to see if they are loaded
        auto_include = []
        self.class.reflect_on_all_associations.each do |reflection|
          next if reflection.macro == :belongs_to # Skip belongs_to to prevent recursion
          auto_include << reflection.name if send(reflection.name).loaded?
        end

        # Add these assocations to the :include if they are not already there
        if include_associations = options.delete(:include)
          if include_associations.is_a?(Hash)
            auto_include.each {|assoc| include_associations[assoc] ||= {}}
          else
            include_associations = Array.wrap(include_associations) | auto_include
          end
          options[:include] = include_associations
        else
          options[:include] = auto_include if auto_include.length > 0
        end

        super(options)
      end

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