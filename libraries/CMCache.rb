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
      # CMCache: Implement a cache with a variable dimensional key structure in memory
      class CMCache
        # initialize: Class constructor
        # PRE: my_num_keys: Number of keys this cache will use
        # POST: None
        # RETURN VALUE: None

        # Disable rubocop eval warnings
        # This class uses eval to metaprogram, but all the keys should come from inside the code.
        # User data should not be used for keys, documented in PRE conditions.
        # rubocop:disable Eval

        def initialize(my_num_keys)
          @num_keys = my_num_keys
        end

        # get: Get a value from the cache
        # PRE: Keys must be strings, not symbols
        #      Keys must be defined in code and not come from user input for security
        # POST: None
        # RETURN VALUE: None
        def get(*keys)
          unless keys.length == @num_keys
            arg_count = keys.length
            fail "Opscode::Rackspace::Monitoring::CMCache.get: Key count mismatch (#{@num_keys}:#{arg_count})"
          end

          unless defined?(@cache)
            return nil
          end

          eval_str = '@cache'
          (0...@num_keys).each do |i|
            key = keys[i]
            cval = eval(eval_str)
            unless cval.key?(key.to_s)
              return nil
            end

            eval_str += "[\"#{key}\"]"
          end

          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCache.get: Returning cached value from #{eval_str}")
          return eval(eval_str)
        end

        # get: Save a value to the cache
        # PRE: Keys must be strings, not symbols
        #      Keys must be defined in code and not come from user input for security
        # POST: None
        # RETURN VALUE: Data or nil
        def save(value, *keys)
          unless keys.length == @num_keys
            arg_count = keys.length
            fail "Opscode::Rackspace::Monitoring::CMCache.save: Key count mismatch (#{@num_keys}:#{arg_count})"
          end

          unless defined?(@cache)
            @cache = {}
          end

          eval_str = '@cache'
          (0...@num_keys).each do |i|
            key = keys[i]
            if key.nil?
              fail "Opscode::Rackspace::Monitoring::CMCache.save: Nil key at index #{i})"
            end

            cval = eval(eval_str)
            unless cval.key?(key.to_s)
              eval("#{eval_str}[\"#{key}\"] = {}")
            end

            eval_str += "[\"#{key}\"]"
          end

          Chef::Log.debug("Opscode::Rackspace::Monitoring::CMCache.save: Saving #{value} to #{eval_str}")
          eval("#{eval_str} = value")

          # Re-enable eval checks
          # rubocop:enable Eval
        end

        # dump: Return the internal cache dictionary
        # Intended for debugging
        # PRE: None
        # POST: None
        # RETURN VALUE: Internal cache
        def dump
          return @cache
        end
      end # END CMCache
    end # END MODULE
  end
end
