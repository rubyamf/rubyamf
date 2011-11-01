source "http://rubygems.org"

gem 'rubyamf', :path => File.dirname(__FILE__)

gem 'rspec', '~>2.6'
gem 'rcov'
gem 'rack', '~>1.0'
gem 'sqlite3-ruby'
gem "RocketAMF", :git => "git://github.com/rubyamf/rocketamf.git"

if true # Rails 2.3
  gem 'rails', '~>2.3'
  gem 'composite_primary_keys', '~> 2.3'
end

if false # Rails 3.0
  gem 'rails', '~>3.0'
  gem 'composite_primary_keys', '~> 3.1.8'
end

if false # Rails 3.1
  # composite_primary_keys currently erroneously requires pg, but I'm commenting out the lines locally
  # see: https://github.com/drnic/composite_primary_keys/issues/44
  gem 'rails', '~>3.1'
  gem 'composite_primary_keys', :git => 'git://github.com/drnic/composite_primary_keys.git'
end