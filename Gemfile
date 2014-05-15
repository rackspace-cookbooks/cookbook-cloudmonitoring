source 'https://rubygems.org'
 
gem 'berkshelf',  '~> 2.0'
 
group :testing do
  gem 'chefspec',   '~> 3.2.0'
  gem 'foodcritic', '~> 3.0.0'
  gem 'thor',       '~> 0.18.0'
  gem 'strainer',   '~> 3.3.0'
  gem 'chef',       '~> 11.8'
  gem 'rspec',      '~> 2.14.0'
  gem 'vagrant-wrapper', '~> 1.2.0'
  gem 'rubocop',    '~> 0.18.0' 

  # Required for this cookbook's ChefSpec tests
  gem 'fog',        '~> 1.19.0'
end
 
group :integration do
  gem 'test-kitchen', '~> 1.1.0'
  gem 'kitchen-vagrant', '~> 0.14.0'
  gem 'kitchen-rackspace', '~> 0.5.0'
  gem 'serverspec', '~> 0.15.0'
end
