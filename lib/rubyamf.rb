require 'rocketamf'
require 'active_support/inflector'

module RubyAMF
  class << self
    def configuration
      @configuration ||= RubyAMF::Configuration.new
    end

    def configure
      yield configuration
      update_configs
    end

    def update_configs
      configuration.propagate
      configuration.preload_models.flatten.each {|m| m.to_s.constantize}
    end

    def array_wrap obj #:nodoc:
      if obj.nil?
        []
      elsif obj.respond_to?(:to_ary)
        obj.to_ary
      else
        [obj]
      end
    end

    def const_missing const #:nodoc:
      if const == :ClassMapper
        class_mapper = RubyAMF.configuration.class_mapper
        RubyAMF.const_set(:ClassMapper, class_mapper)
        RocketAMF.const_set(:ClassMapper, class_mapper)
      else
        super(const)
      end
    end
  end
end

require 'rubyamf/intermediate_object'
require 'rubyamf/class_mapping'
require 'rubyamf/serialization'
require 'rubyamf/configuration'

if defined?(Rails)
  if Rails::VERSION::MAJOR == 3
    puts "bootstrap rails 3"
  elsif Rails::VERSION::MAJOR == 2 && Rails::VERSION::MINOR >= 3
    puts "bootstrap rails 2"
  else
    puts "unsupported rails version"
  end
end