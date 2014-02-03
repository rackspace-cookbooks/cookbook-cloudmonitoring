# encoding: UTF-8
#
# Cookbook Name:: rackspace_cloudmonitoring
# Library:: cloud_monitoring
#
# Copyright 2014, Rackspace, US, Inc.
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

if defined?(ChefSpec)
  def create_monitoring_agent_token(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_agent_token, :create, label)
  end

  def create_if_missing_monitoring_agent_token(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_agent_token, :create_if_missing, label)
  end

  def delete_monitoring_agent_token(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_agent_token, :delete, label)
  end

  def create_monitoring_alarm(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_alarm, :create, label)
  end

  def create_if_missing_monitoring_alarm(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_alarm, :create_if_missing, label)
  end

  def delete_monitoring_alarm(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_alarm, :delete, label)
  end

  def create_monitoring_check(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_check, :create, label)
  end

  def create_if_missing_monitoring_check(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_check, :create_if_missing, label)
  end

  def delete_monitoring_check(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_check, :delete, label)
  end

  def create_monitoring_entity(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_entity, :create, label)
  end

  def create_if_missing_monitoring_entity(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_entity, :create_if_missing, label)
  end

  def delete_monitoring_entity(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudmonitoring_entity, :delete, label)
  end
end
