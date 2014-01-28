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
      # CMApi:  This class initializes the connection to the Cloud Monitoring API
      class CMApi
        # Initialize: Initialize the class
        # Opens connections to the API via Fog, will share connections when possible
        # PRE: credentials is a CMCredentials instance
        # POST: None
        # RETURN VALUE: None
        # Opens @cm class variable
        def initialize(credentials)
          # This class intentionally uses a class variable to share Fog connections across class instances
          # The class variable is guarded by use of the CMCache class which ensures proper connections are utilized
          #    across different class instances.
          # Basically we're in a corner case where class variables are called for.
          # rubocop:disable ClassVars
          username = credentials.get_attribute(:username)
          unless defined? @@cm_cache
            @@cm_cache = CMCache.new(1)
          end
          @cm = @@cm_cache.get(username)
          unless @cm.nil?
            Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi.initialize: Reusing existing Fog connection for username #{username}")
            return
          end

          # No cached cm, create a new one
          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMApi.initialize: creating new Fog connection for username #{username}")
          @cm = Fog::Rackspace::Monitoring.new(
                                               rackspace_api_key: credentials.get_attribute(:api_key),
                                               rackspace_username: username,
                                               rackspace_auth_url: credentials.get_attribute(:auth_url)
                                               )

          if @cm.nil?
            fail 'Opscode::Rackspace::Monitoring::CMApi.initialize: ERROR: Unable to connect to Fog'
          end
          Chef::Log.debug('Opscode::Rackspace::Monitoring::CMApi.initialize: Fog connection successful')

          @@cm_cache.save(@cm, username)

          # Re-enable ClassVars rubocop errors
          # rubocop:enable ClassVars
        end

        # cm: Getter for the @@cm class variable
        # PRE: None
        # POST: None
        # RETURN VALUE: Fog::Rackspace::Monitoring class
        def cm
          return @cm
        end

        # mock?: Return if we are mocked
        # PRE: None
        # POST: None
        # RETURN VALUE: Boolean
        def mock?
          Fog.mock?
        end
      end # END CMApi class
    end # END MODULE
  end
end
