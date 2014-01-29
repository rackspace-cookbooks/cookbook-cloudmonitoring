source 'https://rubygems.org'
 
gem 'berkshelf',  '~> 2.0'
 
group :testing do
  gem 'chefspec',   '~> 3.0'
  gem 'foodcritic', '~> 3.0'
  gem 'thor',       '~> 0.18'
  gem 'strainer',   '~> 3.3'
  gem 'chef',       '~> 11.0'
  gem 'rspec',      '~> 2.14'
  gem 'vagrant-wrapper', '~> 1.2'

  # Rubocop 0.16 is recently broken
#  gem 'rubocop',    '~> 0.16' 
  # But Rubocop 0.17 conflicts with Chef out of the box
  # https://github.com/bbatsov/rubocop/issues/761
  gem 'rubocop',    :git => 'https://github.com/RSTJNII/rubocop.git', :branch => 'gemhackery'

  # Required for this cookbook's ChefSpec tests
  gem 'fog',        '~> 1.19'
end
 
group :integration do
  gem 'test-kitchen', '~> 1.0'
  gem 'kitchen-vagrant', '~> 0.14'
end
