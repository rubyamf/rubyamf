require 'rubygems'
require "bundler/setup"

require 'spec'
require 'spec/autorun'
require 'rubyamf'

# Active record setup
require 'active_record'
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database  => ':memory:')
ActiveRecord::Schema.define do
  create_table "parents" do |t|
    t.string "name"
  end
  create_table "children" do |t|
    t.string "name"
    t.integer "parent_id"
  end
end
class Parent < ActiveRecord::Base
  has_many :children
end
class Child < ActiveRecord::Base
  belongs_to :parent
end
p = Parent.create :name => "parent"
p.children.create :name => "child 1"
p.children.create :name => "child 2"

# Make sure RubyAMF has initialized (load AR hooks, define ClassMapper)
RubyAMF.bootstrap