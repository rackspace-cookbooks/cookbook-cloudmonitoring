#
# Cookbook Name:: rackspace_cloudmonitoring
#
# Copyright 2014, Rackspace, US, Inc.
# Copyright 2013-2014 Chef Software, Inc.
# Copyright 2011 Fletcher Nichol
# Copyright 2010 VMware, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Originally from https://github.com/opscode-cookbooks/jenkins/blob/master/Rakefile
#
# Tasks can be called individually: bundle exec rake style_unit

require 'bundler/setup'

namespace :style do
  require 'rubocop/rake_task'
  desc 'Run Ruby style checks'
  Rubocop::RakeTask.new(:ruby)

  require 'foodcritic'
  desc 'Run Chef style checks'
  FoodCritic::Rake::LintTask.new(:chef) { |task| 
    task.options = { fail_tags: ['any'] }
  }
end

desc 'Run all style checks'
task style: ['style:chef', 'style:ruby']

require 'rspec/core/rake_task'
desc 'Run RSpec and ChefSpec unit tests'
RSpec::Core::RakeTask.new(:unit)

desc 'Run style and unit tests'
task style_unit: ['style:chef', 'style:ruby', 'unit']

require 'kitchen'
desc 'Run Test Kitchen integration tests'
task :integration do
  Kitchen.logger = Kitchen.default_file_logger
  Kitchen::Config.new.instances.each do |instance|
    instance.test(:always)
  end
end

# We cannot run Test Kitchen on Travis CI yet...
namespace :travis do
  desc 'Run tests on Travis'
  task ci: ['style']
end

# The default rake task should just run it all
task default: ['style', 'unit', 'integration']
