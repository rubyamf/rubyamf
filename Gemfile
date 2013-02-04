source "http://rubygems.org"

gem 'rubyamf', :path => File.dirname(__FILE__)

gem 'rspec', '~>2.6'
gem 'rcov'
gem 'rdoc'
gem 'rack', '~>1.0'
gem 'sqlite3'
gem "RocketAMF", :git => "git://github.com/rubyamf/rocketamf.git"

case 'Rails 3.1'
  when 'Rails 2.3'
    gem 'rails', '~>2.3'
    gem 'composite_primary_keys', '~> 2.3'
  when 'Rails 3.0'
    gem 'rails', '~>3.0'
    gem 'composite_primary_keys', '~> 3.1.8'
  when 'Rails 3.1'
    gem 'rails', '~>3.1'
    gem 'composite_primary_keys', '~> 4'
end