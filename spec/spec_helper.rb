require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'rspec/autorun'

if (RUBY_VERSION.split('.').map(&:to_i) <=> [1, 9]) >= 0
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
end

begin
  # Rails 3+
  require 'rails'
rescue LoadError => e
  # Rails 2.3
  require 'initializer'
  RAILS_ROOT = File.dirname(__FILE__)
  Rails.configuration = Rails::Configuration.new
end

# Active record setup
require 'active_record'
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database  => ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)
require 'composite_primary_keys'

ActiveRecord::Schema.define do
  create_table "parents" do |t|
    t.string "name"
  end
  create_table "homes" do |t|
    t.string "address"
    t.integer "parent_id"
  end
  create_table "children" do |t|
    t.string "name"
    t.integer "parent_id"
  end
end

class Parent < ActiveRecord::Base
  has_many :children
  has_one :home
end

class Home < ActiveRecord::Base
  belongs_to :parent
end

class Child < ActiveRecord::Base
  belongs_to :parent
  attr_accessor :meth
end

class CompositeChild < ActiveRecord::Base
  if ::ActiveRecord::VERSION::STRING < '3.2'
    set_table_name "children"
    set_primary_keys :id, :name
  else
    self.table_name = "children"
    self.primary_keys = [:id, :name]
  end

end

# Load RubyAMF
require 'rubyamf'
RubyAMF.bootstrap
