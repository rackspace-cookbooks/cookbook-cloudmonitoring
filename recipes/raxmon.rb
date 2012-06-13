#
# Cookbook Name:: raxmon-cli
# Recipe:: default
#
# Copyright 2012, Rackspace Hosting
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
include_recipe "python"

if Chef::DataBag.list.keys.include?("rackspace") && data_bag("rackspace").include?("cloud")
  #Access the Rackspace Cloud encrypted data_bag
  raxcloud = Chef::EncryptedDataBagItem.load("rackspace","cloud")

  #Create variables for the Rackspace Cloud username and apikey
  raxusername = raxcloud['raxusername']
  raxapikey = raxcloud['raxapikey']

  #Create the .raxrc with credentials in /root
  template "/root/.raxrc" do
    source "raxrc.erb"
    owner "root"
    group "root"
    mode 0600
    variables(
      :raxusername => raxusername,
      :raxapikey => raxapikey
    )
  end
else
	Chef::Log.info "rackspace data bag with item cloud does not exist, skipping .raxrc creation"
end

#Install the raxmon-cli
python_pip "rackspace-monitoring-cli" do
  action :upgrade
end
