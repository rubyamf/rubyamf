require 'rocketamf'
require 'active_support/inflector'

require 'rubyamf/version'
require 'rubyamf/intermediate_object'
require 'rubyamf/class_mapping'
require 'rubyamf/serialization'
require 'rubyamf/configuration'
require 'rubyamf/request_parser'
require 'rubyamf/request_processor'

module RubyAMF
  MIME_TYPE = "application/x-amf".freeze

  class << self
    def configuration
      @configuration ||= RubyAMF::Configuration.new
    end

    def configure
      yield configuration
      bootstrap
    end

    def bootstrap
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

if defined?(Rails)
  if Rails::VERSION::MAJOR == 3
    require 'rubyamf/rails3/bootstrap'
  elsif Rails::VERSION::MAJOR == 2 && Rails::VERSION::MINOR >= 3
    require 'rubyamf/rails2/bootstrap'
  else
    puts "unsupported rails version"
  end
end