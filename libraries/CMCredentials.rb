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
      # CMCredentials: Class for handling the various credential sources
      #
      # As of 5/8/14 this class is two lines too long, mostly from the attribute map.
      # While cutting 3 lines is doable, it would just pop back when a new attribute is defined
      #  and would not improve overall code quality.  Disable the ClassLength cop here.
      class CMCredentials # rubocop:disable ClassLength
        def initialize(my_node, my_resource)
          @node = my_node
          @resource = my_resource
          @databag_data = load_databag

          # @attribute_map: This is a mapping of how the attributes are named ant stored
          # in the various source structures
          @attribute_map = {
            api_key: {
              resource: 'rackspace_api_key',
              node:     '["rackspace"]["cloud_credentials"]["api_key"]',
              databag:  'apikey'
            },
            username: {
              resource: 'rackspace_username',
              node:     '["rackspace"]["cloud_credentials"]["username"]',
              databag:  'username'
            },
            auth_url: {
              resource: 'rackspace_auth_url',
              node:     '["rackspace_cloudmonitoring"]["auth"]["url"]',
              databag:  'auth_url'
            },
            token: {
              resource: 'monitoring_agent_token',
              node:     '["rackspace_cloudmonitoring"]["config"]["agent"]["token"]',
              databag:  'agent_token'
            },
            mocking: {
              resource: 'monitoring_mock_api',
              node:     '["rackspace_cloudmonitoring"]["mock"]',
              databag:  nil
            },
            pagination_limit: {
              resource: nil,
              node:     '["rackspace_cloudmonitoring"]["api"]["pagination_limit"]',
              databag:  nil
            }
          }
        end

        # get_*_attribute(): Get an attribute from the appropriate section
        # Intended to be called by get_attribute()
        # PRE: attribute_name key exists in @attribute_map
        # POST: None
        # RETURN VALUE: Data or nil
        def _get_resource_attribute(attribute_name)
          if @attribute_map[attribute_name][:resource].nil?
            return nil
          end

          # Resource attributes are called as methods, so use send to access the attribute
          begin
            resource = @resource.nil? ? nil : @resource.send(@attribute_map[attribute_name][:resource])
          rescue NoMethodError
            resource = nil
          end

          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCredentials.get_attribute: Resource value for attribute #{attribute_name}: #{resource}")
          return resource
        end

        def _get_node_attribute(attribute_name)
          if @attribute_map[attribute_name][:node].nil?
            return nil
          end

          # Note is a hash, so use eval to tack on the indexes
          begin
            # Disable rubocop eval warnings
            # The @attribute_map[attribute_name][:node] variable is set in the constructor
            #   Security for attribute_name documented in PRE conditions
            # rubocop:disable Eval
            node_val = eval("@node#{@attribute_map[attribute_name][:node]}")
            # rubocop:enable Eval
          rescue NoMethodError
            node_val = nil
          end

          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCredentials.get_attribute: Node value for attribute #{attribute_name}: #{node_val}")
          return node_val
        end

        def _get_databag_attribute(attribute_name)
          if @attribute_map[attribute_name][:databag].nil?
            return nil
          end

          # databag is just a hash set by load_databag which is controlled in this class
          # TODO: Take this .to_sym call requirement out back and beat it with a shovel
          databag = @databag_data[@attribute_map[attribute_name][:databag].to_sym]

          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCredentials.get_attribute: Databag value for attribute #{attribute_name}: #{databag}")
          return databag
        end

        # get_attribute: get an attribute
        # PRE: attribute_name must be defined in code and not come from user input for security
        # POST: None
        def get_attribute(attribute_name)
          unless @attribute_map.key? attribute_name
            fail "Opscode::Rackspace::Monitoring::CMCredentials.get_attribute: Attribute #{attribute_name} not defined in @attribute_map"
          end

          # I think this is about as clean as this code can be without redefining the LWRP arguments
          # and databag storage, which is simply too much of a refactor.
          ret_val =  _precidence_logic(_get_resource_attribute(attribute_name),
                                       _get_node_attribute(attribute_name),
                                       _get_databag_attribute(attribute_name))
          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCredentials.get_attribute: returning \"#{ret_val}\" for attribute #{attribute_name}")
          return ret_val
        end

        # load_databag: Load credentials from the databag
        # PRE: Databag details defined in node['rackspace_cloudmonitoring']['auth']['databag'] attributes
        # POST: None
        # RETURN VALUE: Data on success, empty hash on error
        # DOES NOT SET @databag_data
        def load_databag
          # Ignore the databag if the values aren't set
          begin
            @node['rackspace_cloudmonitoring']['auth']['databag']['name']
            @node['rackspace_cloudmonitoring']['auth']['databag']['item']
          rescue NoMethodError
            return {}
          end

          # Access the Rackspace Cloud encrypted data_bag
          begin
            return Chef::EncryptedDataBagItem.load(@node['rackspace_cloudmonitoring']['auth']['databag']['name'],
                                                   @node['rackspace_cloudmonitoring']['auth']['databag']['item'])

          # Every different incantation of Chef, be it ChefSpec, ChefSolo, or full Chef, throws a different exception when the databag is missing
          #   It unfortunately isn't practical to try and target this.
          rescue Exception # rubocop:disable RescueException
            return {}
          end
        end

        # precidence_logic: Helper method to handle precidence of attributes
        # from the resource, node attributes, and databas
        # PRE: None
        # POST: None
        def _precidence_logic(resource, node, databag)
          # Precedence:
          # 1) new_resource variables (If available)
          # 2) Node data
          # 3) Data bag
          if resource
            return resource
          end

          if node
            return node
          end

          return databag
        end
      end # END CMCredentials
    end # END MODULE
  end
end
