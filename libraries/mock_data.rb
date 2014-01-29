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

module Opscode
  module Rackspace
    module Monitoring
      module MockData
        # MockMonitoring: provide an object mimicing Fog::Rackspace::Monitoring
        class MockMonitoring
          attr_accessor :entities, :agent_tokens

          def initialize(options = {})
            if options[:rackspace_api_key].nil?
              fail 'ERROR: Opscode::Rackspace::Monitoring::MockData::MockMonitoring.initialize: Mandatory argument rackspace_api_key unset'
            end
            if options[:rackspace_username].nil?
              fail 'ERROR: Opscode::Rackspace::Monitoring::MockData::MockMonitoring.initialize: Mandatory argument rackspace_username unset'
            end

            @entities = MockMonitoringParent.new(MockMonitoringEntity)
            @agent_tokens = MockMonitoringParent.new(MockMonitoringAgentToken)
          end
        end

        # MockMonitoringParent: Emulate the parent Fog object, inhereiting Array
        class MockMonitoringParent < Array
          def initialize(my_child_obj_class)
            @child_obj_class = my_child_obj_class
          end

          # Overload new
          def new(options = {})
            return @child_obj_class.new(self, options)
          end
        end

        # MockMonitoringParent: Emulate the parent of the Fog entity child objects, inhereiting Array
        # This is the same as MockMonitoringParent, except it passes the entity object to the child constructor
        class MockMonitoringEntityParent < Array
          def initialize(my_child_obj_class, my_entity)
            @child_obj_class = my_child_obj_class
            @entity = my_entity
          end

          # Overload new
          def new(options = {})
            return @child_obj_class.new(self, @entity, options)
          end
        end

        # MockMonitoringBase: Class mimicing the save and destroy, Fog object methods, and providing common helpers
        class MockMonitoringBase
          def initialize(my_parent)
            @parent = my_parent
          end

          def save
            @parent.push(self)
          end

          def destroy
            @parent.delete(self)
          end

          def _compare_helper(other_obj, attributes)
            attributes.each do |attr|
              if send(attr) != other_obj.send(attr)
                return false
              end
            end
            return true
          end

          def random_id
            src = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
            return (0...10).map { src[rand(src.length)] }.join
          end
        end

        # MockMonitoringEntity: Mimic a Fog entity object
        class MockMonitoringEntity < MockMonitoringBase
          attr_accessor :id, :label, :metadata, :ip_addresses, :agent_id, :managed, :uri, :alarms, :checks
          attr_writer   :id, :label, :metadata, :ip_addresses, :agent_id, :managed, :uri

          def initialize(parent, options = {})
            super(parent)

            @id = random_id
            options.each do |k, v|
              unless %w(label metadata ip_addresses agent_id managed uri).include? k
                fail "Unknown option #{k}"
              end
              instance_variable_set("@#{k}", v)
            end

            @alarms = MockMonitoringEntityParent.new(MockMonitoringAlarm, self)
            @checks = MockMonitoringEntityParent.new(MockMonitoringCheck, self)
          end

          def compare?(other_obj)
            _compare_helper(other_obj, [:id, :label, :metadata, :ip_addresses, :agent_id, :managed, :uri])
          end
        end

        # MockMonitoringAlarm: Mimic a Fog alarm object
        class MockMonitoringAlarm < MockMonitoringBase
          attr_accessor :id, :entity, :check, :label, :criteria, :check_type, :notification_plan_id
          attr_writer   :id, :entity, :check, :label, :criteria, :check_type, :notification_plan_id

          def initialize(parent, my_entity, options = {})
            super(parent)

            @entity = my_entity
            @id = random_id
            options.each do |k, v|
              unless %w(check label criteria check_type notification_plan_id).include? k
                fail "Unknown option #{k}"
              end
              instance_variable_set("@#{k}", v)
            end

            if @check.nil?
              fail 'check is required'
            end
            if @notification_plan_id.nil?
              fail 'notification_plan_id is required'
            end
          end

          def compare?(other_obj)
            _compare_helper(other_obj, [:id, :entity, :check, :label, :criteria, :check_type, :notification_plan_id])
          end
        end

        # MockMonitoringCheck: Mimic a Fog check object
        class MockMonitoringCheck < MockMonitoringBase
          attr_accessor :id, :entity, :label, :metadata, :target_alias, :target_resolver, :target_hostname, :period, :timeout, :type, :details, :disabled, :monitoring_zones_poll
          attr_writer   :id, :entity, :label, :metadata, :target_alias, :target_resolver, :target_hostname, :period, :timeout, :details, :disabled, :monitoring_zones_poll

          def initialize(parent, my_entity, options = {})
            super(parent)

            @entity = my_entity
            @id = random_id
            options.each do |k, v|
              unless %w(label metadata target_alias target_resolver target_hostname period timeout type details disabled monitoring_zones_poll).include? k
                fail "Unknown option #{k}"
              end
              instance_variable_set("@#{k}", v)
            end

            if @type.nil?
              fail 'Type is required'
            end
          end

          def compare?(other_obj)
            _compare_helper(other_obj, [:id, :entity, :label, :metadata, :target_alias, :target_resolver, :target_hostname,
                                        :period, :timeout, :type, :details, :disabled, :monitoring_zones_poll])
          end
        end

        # MockMonitoringAgentToken: Mimic a Fog agent_token object
        class MockMonitoringAgentToken < MockMonitoringBase
          attr_accessor :label, :id
          attr_writer   :label

          def initialize(parent, options = {})
            super(parent)

            @id = random_id
            options.each do |k, v|
              unless %w(label).include? k
                fail "Unknown option #{k}"
              end
              instance_variable_set("@#{k}", v)
            end
          end

          def token
            return @id
          end

          def compare?(other_obj)
            _compare_helper(other_obj, [:id, :label])
          end
        end
      end
    end
  end
end
