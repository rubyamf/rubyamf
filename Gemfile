source "http://rubygems.org"

gem 'rubyamf', :path => File.dirname(__FILE__)

gem 'rspec', '~>2.13.0'
gem 'rdoc'
gem 'rack', '~>1.0'
gem 'sqlite3'
gem "RocketAMF", :git => "git://github.com/rubyamf/rocketamf.git"

if (RUBY_VERSION.split('.').map(&:to_i) <=> [1, 9]) >= 0
  gem 'simplecov'
else
  gem 'rcov'
end

case "#{ENV['RAILS_VERSION']}"
when '2.3'
  gem 'rails', '~>2.3'
  gem 'composite_primary_keys', '~> 2.3'
when '3.0'
  gem 'rails', '~>3.0.0'
  gem 'composite_primary_keys', '~> 3.1.8'
when '3.1'
  gem 'rails', '~>3.1.0'
  gem 'composite_primary_keys', '~> 4'
when '3.2'
  gem 'rails', '~>3.2.0'
  gem 'composite_primary_keys', '~> 5'
else
  gem 'rails', '~>4.0'
  gem 'composite_primary_keys', '~> 6'
end
