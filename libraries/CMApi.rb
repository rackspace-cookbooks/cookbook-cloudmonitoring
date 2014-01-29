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

require_relative 'CMCache.rb'

module Opscode
  module Rackspace
    module Monitoring
      # CMApi:  This class initializes the connection to the Cloud Monitoring API
      class CMApi
        # Initialize: Initialize the class
        # Opens connections to the API via Fog, will share connections when possible
        # PRE: credentials is a CMCredentials instance
        # POST: None
        # RETURN VALUE: None
        # Opens @cm class variable
        def initialize(my_credentials)
          if my_credentials.nil?
            fail 'Opscode::Rackspace::Monitoring::CMApi.initialize: ERROR: Mandatory argument my_credentials nil'
          end

          @credentials = my_credentials

          @mocking = @credentials.get_attribute(:mocking)

          # This class intentionally uses a class variable to share Fog connections across class instances
          # The class variable is guarded by use of the CMCache class which ensures proper connections are utilized
          #    across different class instances.
          # Basically we're in a corner case where class variables are called for.
          # rubocop:disable ClassVars
          username = @credentials.get_attribute(:username)
          unless defined? @@cm_cache
            @@cm_cache = Opscode::Rackspace::Monitoring::CMCache.new(1)
          end
          @cm = @@cm_cache.get(username)
          # rubocop:enable ClassVars

          unless @cm.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi.initialize: Reusing existing Fog connection for username #{username}")
            return
          end
        end

        # _open_connection: Open the connection to the API using the approproate method
        # PRE: None
        # POST: None
        # RETURN VALUE: None
        def _open_connection(api_key, username, auth_url)
          if @mocking
            _open_mock_api(api_key, username, auth_url)
          else
            # Oooh, mock me Amadaeus
            _open_fog_api(api_key, username, auth_url)
          end
          @@cm_cache.save(@cm, username) # rubocop:disable ClassVars
        end

        # _open_fog_api: Open the connection to the Fog API
        # PRE: None
        # POST: None
        # Return Value: None
        # Sets @cm
        def _open_fog_api(api_key, username, auth_url)
          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi._open_fog_api: creating new Fog connection for username #{username}")
          @cm = Fog::Rackspace::Monitoring.new(
                                               rackspace_api_key:  api_key,
                                               rackspace_username: username,
                                               rackspace_auth_url: auth_url
                                               )

          if @cm.nil?
            fail 'Opscode::Rackspace::Monitoring::CMApi._open_fog_api: ERROR: Unable to connect to Fog'
          end
          Chef::Log.debug('Opscode::Rackspace::Monitoring::CMApi._open_fog_api: Fog connection successful')
        end

        # _open_mock_api: Mock a fake API connection
        # PRE: None
        # POST: None
        # Return Value: None
        # Sets @cm
        def _open_mock_api(api_key, username, auth_url)
          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi._open_fog_api: creating new mocked connection for username #{username}")
          require_relative 'mock_data.rb'

          @cm = Opscode::Rackspace::Monitoring::MockData::MockMonitoring.new(
                                                                             rackspace_api_key:  api_key,
                                                                             rackspace_username: username,
                                                                             rackspace_auth_url: auth_url
                                                                             )
        end

        # cm: Getter for the @cm variable
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring class
        def cm
          if @cm.nil?
            # No open cm, create a new one
            _open_connection(@credentials.get_attribute(:api_key),
                             @credentials.get_attribute(:username),
                             @credentials.get_attribute(:auth_url))
          end

          return @cm
        end

        # mock?: Return if we are mocked
        # PRE: None
        # POST: None
        # RETURN VALUE: Boolean
        def mock?
          return @mocking
        end

        # mock!: Enable mocking
        # PRE: None
        # POST: None
        # RETURN VALUE: None
        def mock!
          @mocking = true
        end
      end # END CMApi class
    end # END MODULE
  end
end
