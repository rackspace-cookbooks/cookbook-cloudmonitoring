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
          attr_accessor :entities, :agent_tokens, :alarm_examples

          def initialize(options = {})
            if options[:rackspace_api_key].nil?
              fail 'ERROR: Opscode::Rackspace::Monitoring::MockData::MockMonitoring.initialize: Mandatory argument rackspace_api_key unset'
            end
            if options[:rackspace_username].nil?
              fail 'ERROR: Opscode::Rackspace::Monitoring::MockData::MockMonitoring.initialize: Mandatory argument rackspace_username unset'
            end

            @entities = MockMonitoringParent.new(MockMonitoringEntity)
            @agent_tokens = MockMonitoringParent.new(MockMonitoringAgentToken)
            @alarm_examples = MockMonitoringAlarmExamples.new
          end
        end

        # MockMonitoringParent: Emulate the parent Fog object, inhereiting Array
        class MockMonitoringParent < Array
          attr_accessor :marker

          def initialize(my_child_obj_class)
            @child_obj_class = my_child_obj_class
          end

          # Add the all method, used by Fog pagination
          def all(options = {})
            # Create my_options with default
            my_options = {
              limit: 100,
              marker: nil
            }.merge(options)

            # Limits per http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/api-paginated-collections.html
            if my_options[:limit].nil?
              fail 'ERROR: Opscode::Rackspace::Monitoring::MockData::MockMonitoringParent.all: Passed nil limit'
            end

            if my_options[:limit] < 1 || my_options[:limit] > 1000
              fail "ERROR: Opscode::Rackspace::Monitoring::MockData::MockMonitoringParent.all: Illegal limit #{my_options[:limit]}"
            end

            # Locate the index of the specified marker
            if my_options[:marker].nil?
              start_index = 0
            else
              target = find { |t| t.id == my_options[:marker] }
              if target.nil?
                start_index = 0
              else
                start_index = index(target)
              end
            end

            # Emulate Fog pagination
            ret_val = slice(start_index, my_options[:limit])

            # Set the marker for pagination
            if (start_index + my_options[:limit]) < length
              ret_val.marker = self[(start_index + my_options[:limit])].id
            else
              ret_val.marker = nil
            end

            return ret_val
          end

          # Overload new
          def new(options = {})
            return @child_obj_class.new(self, options)
          end
        end

        # MockMonitoringChildObjParent: Emulate the parent of the Fog entity child objects, inhereiting Array
        # This is the same as MockMonitoringParent, except it passes the entity object to the child constructor
        class MockMonitoringChildObjParent < MockMonitoringParent
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
            # Overwrite objects with matching IDs
            existing_obj = @parent.find { |o| o.id == id }
            if existing_obj.nil?
              @parent.push(self)
            else
              @parent[@parent.index(existing_obj)] = self
            end
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
              unless %w(label metadata ip_addresses agent_id managed uri).include? k.to_s
                fail "Unknown option #{k}"
              end
              instance_variable_set("@#{k}", v)
            end

            @alarms = MockMonitoringChildObjParent.new(MockMonitoringAlarm, self)
            @checks = MockMonitoringChildObjParent.new(MockMonitoringCheck, self)
          end

          def compare?(other_obj)
            _compare_helper(other_obj, [:id, :label, :metadata, :ip_addresses, :agent_id, :managed, :uri])
          end
        end

        # MockMonitoringAlarm: Mimic a Fog alarm object
        class MockMonitoringAlarm < MockMonitoringBase
          attr_accessor :id, :entity, :label, :check, :criteria, :notification_plan_id, :disabled, :metadata
          attr_writer   :id, :entity, :label, :check, :criteria, :notification_plan_id, :disabled, :metadata

          def initialize(parent, my_entity, options = {})
            super(parent)

            @entity = my_entity
            @id = random_id
            options.each do |k, v|
              unless %w(check label criteria notification_plan_id disabled metadata).include? k.to_s
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
            _compare_helper(other_obj, [:id, :entity, :label, :check, :criteria, :notification_plan_id, :disabled, :metadata])
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
              unless %w(label metadata target_alias target_resolver target_hostname period timeout type details disabled monitoring_zones_poll).include? k.to_s
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
              unless %w(label).include? k.to_s
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

        # MockMonitoringAlarmExample: Mimic a Alarm Example object
        class MockMonitoringAlarmExample
          attr_accessor :id, :label, :description, :check_type, :criteria, :fields, :bound_criteria
          attr_writer   :id, :label, :description, :check_type, :criteria, :fields, :bound_criteria
          # Oh the complexity!
        end

        # MockMonitoringAlarmExamples: Mimic the Fog alarm examples object
        class MockMonitoringAlarmExamples < Array
          def initialize
            # Seed ourself with some data
            # This data is straight from the API, keep rubocop from complaining about it
            # rubocop:disable LineLength
            _seed(id:    'remote.http_body_match_1',
                  label: 'Body match - string found',
                  description: 'Alarm which returns CRITICAL if the provided string is found in the body',
                  check_type: 'remote.http',
                  criteria: "if (metric['body_match'] regex '${string}') {\n  return new AlarmStatus(CRITICAL, '${string} found, returning CRITICAL.');\n}\n",
                  fields: [{ 'name' => 'string', 'description' => 'String to check for in the body', 'type' => 'string' }])
            _seed(id: 'remote.http_body_match_missing_string',
                  label: 'Body match - string not found',
                  description: 'Alarm which returns CRITICAL if the provided string is not found in the body',
                  check_type: 'remote.http',
                  criteria: "if (metric['body_match'] == '') {\n  return new AlarmStatus(CRITICAL, 'HTTP response did not contain the correct content.');\n}\n\nreturn new AlarmStatus(OK, 'HTTP response contains the correct content');\n",
                  fields: [])
            _seed(id: 'remote.http_connection_time',
                  label: 'Connection time',
                  description: 'Alarm which returns WARNING or CRITICAL based on the connection time',
                  check_type: 'remote.http',
                  criteria: "if (metric['duration'] > ${critical_threshold}) {\n  return new AlarmStatus(CRITICAL, 'HTTP request took more than ${critical_threshold} milliseconds.');\n}\n\nif (metric['duration'] > ${warning_threshold}) {\n  return new AlarmStatus(WARNING, 'HTTP request took more than ${warning_threshold} milliseconds.');\n}\n\nreturn new AlarmStatus(OK, 'HTTP connection time is normal');\n",
                  fields: [{ 'name' => 'warning_threshold',
                             'description' => 'Warning threshold (in milliseconds) for the connection time',
                             'type' => 'integer' },
                           { 'name' => 'critical_threshold',
                             'description' =>
                             'Critical threshold (in milliseconds) for the connection time',
                             'type' => 'integer' }]
                  )
            # rubocop:enable LineLength
          end

          # _seed: Seed ourselves with data
          def _seed(options)
            obj = MockMonitoringAlarmExample.new
            obj.id             = options[:id]
            obj.label          = options[:label]
            obj.description    = options[:description]
            obj.check_type     = options[:check_type]
            obj.criteria       = options[:criteria]
            obj.fields         = options[:fields]
            obj.bound_criteria = options[:bound_criteria]
            push(obj)
          end

          # evaluate: Mimic the fog evaluate method
          def evaluate(id, options = {})
            example = find { |e| e.id == id }
            if example.nil?
              fail "ERROR: Opscode::Rackspace::Monitoring::MockData::MockMonitoringAgentToken.evaluate: No match for id #{id}"
            end

            if example.fields.map { |f| f['name'] } != options.keys
              fail "ERROR: Opscode::Rackspace::Monitoring::MockData::MockMonitoringAgentToken.evaluate: Options mismatch for id #{id}"
            end

            ret_val = example.dup
            ret_val.bound_criteria = '# This is dummy data'
            return ret_val
          end
        end
      end
    end
  end
end
