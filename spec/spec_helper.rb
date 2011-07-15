require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'rspec/autorun'

begin
  # Rails 3+
  require 'rails'
rescue LoadError => e
  # Rails 2.3
  require 'initializer'
  RAILS_ROOT = File.dirname(__FILE__)
  Rails.configuration = Rails::Configuration.new
end

require 'rubyamf'

# Active record setup
require 'active_record'
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database  => ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)
require 'composite_primary_keys'

# Make sure RubyAMF has initialized (load AR hooks, define ClassMapper)
RubyAMF.bootstrap