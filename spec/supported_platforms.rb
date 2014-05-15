#
# Cookbook Name:: rackspace_cloudmonitoring
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

# This helper file defines the platforms to test in ChefSpec

def rackspace_cloudmonitoring_test_platforms
  return {
    ubuntu: %w(12.04),
    debian: %w(7.2), # Requires Fauxhai chicanery as https://github.com/customink/fauxhai/pull/60
                     #   hasn't made its way to RubyGems yet.
    centos: %w(6.4 6.5)
  }
end
