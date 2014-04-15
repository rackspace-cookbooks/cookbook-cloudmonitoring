rackspace_cloudmonitoring Cookbook
===================================

NOTE: v2.0.0 is a major rewrite with breaking changes.  Please review this readme for new usage and check the changelog
-----------------------------------------------------------------------------------------------------------------------

# Description

This cookbook provides automated way to manage the various resources using the Rackspace Cloud Monitoring API.
Specifically this recipe will focus on main atom's in the system.

* Entities
* Checks
* Alarms
* Agent
* Agent Tokens

# General Requirements
* Chef 11
* A Rackspace Cloud Hosting account is required to use this tool.  And a valid `username` and `api_key` are required to authenticate into your account.  [sign-up](https://cart.rackspace.com/cloud/?cp_id=cloud_monitoring).

# Credential Handling

As this Cookbook is API focused, credentials for the API are required.
These credentials can be passed to the resource providers, loaded from an encrypted databag, or pulled from Node attributes.

| Credential | Required | Default | Node Attribute | Databag Attribute |
| ---------- | -------- | ------- | -------------- | ----------------- |
| API Key    | Yes      | NONE    | node['rackspace"]['cloud_credentials']['api_key'] | apikey |
| API Username | Yes    | NONE    | node['rackspace"]['cloud_credentials']['username'] | username |
| API Auth URL | No     | Defined in attributes.rb | node['rackspace_cloudmonitoring']['auth']['url'] | auth_url |
| Agent Token | No      | Generated via API | node['rackspace_cloudmonitoring']['config']['agent']['token'] | agent_token |

Note that the API Key and API Username use the shared node['rackspace"]['cloud_credentials'] namespace, not the node['rackspace_cloudmonitoring'] namespace.
Passing values in via Resource providers will be covered in the LWRP section.

Precedence is as follows:

1. LWRP arguments
2. Node attributes
3. Databag

The details of the databag are as follows:

| Credential | Default | Node Attribute |
| ---------- | ------- | -------------- |
| Name       | Defined in attributes.rb | node['rackspace_cloudmonitoring']['auth']['databag']['name'] |
| Item	     | Defined in attributes.rb | node['rackspace_cloudmonitoring']['auth']['databag']['item'] |

# Usage

## Recipes

This cookbook is broken up into 3 recipes:

| Recipe  | Purpose |
| ------  | ------- |
| default | Installs dependencies needed by the other recipes and Resource providers. |
| agent   | Installs and configures the Cloud Monitoring server agent daemon. |
| monitors | Parses the monitors configuration hash to configure the entity, checks, and alarms |

## Configuration hash usage

The simplest and preferred way to utilize this cookbook is via a configuration hash.
The configuration hash defines the desired monitors and alarms for the server.
The monitors recipe handles all dependencies for configuring the defined checks and will install the agent on the server.

The base namespace is node['rackspace_cloudmonitoring']['monitors'].
node['rackspace_cloudmonitoring']['monitors'] is a hash where each key is the name of a check.
The value is a second hash where the keys are the following attributes:

| Key    | Value Data type | Description | Required | API Documentation Attribute Name | Default Value | Note |
| ------ | --------------- | ----------- | -------- | -------------------------------- | ------------- | ---- |
| type   | String | Check type  | Yes      | type                             | None          |  |
| alarm | Hash | Hash of alarms for this check.  See below. | No | N/A | None | This value is not a API value, it is specific to this cookbook. |
| details | Hash | Detail data needed by the check | No | details | None | See API documentation for details on details. |
| disabled | Boolean | Disables the check when true | No | disabled | false | -- |
| metadata | Hash | Metadata to associate with the check | No | metadata | None |  |
| monitoring_zones_poll | Array | Array of zones to poll remote checks from | No | monitoring_zones_poll | None | Only used with remote checks, See API docs for valid zones |
| period | Integer | The period in seconds for a check | No | period           | node['rackspace_cloudmonitoring']['monitors_defaults']['check']['period'] | The value must be greater than the minimum period set on your account. |
| target_alias    | string | Key in the entity's 'ip_addresses' hash used to resolve check to an IP address for remote checks | No | target_alias | None | Only used with remote checks, See API documentation |
| target_hostname | string | Hostname a remote check should target | No | target_hostname | None | Only used with remote checks, See API documentation |
| target_resolver | string | Method to resolve remote checks | No | target_resolver | None | Only used with remote checks, See API documentation |
| timeout | Integer | The timeout in seconds for a check | No | timeout | node['rackspace_cloudmonitoring']['monitors_defaults']['check']['timeout'] | This has to be less than the period. |



The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Checks](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-checks.html)
As you can see the node['rackspace_cloudmonitoring']['monitors_defaults'] node hash is used to define defaults so that common options don't need to be defined for every check.
The values for each check is passed to the rackspace_cloudmonitoring_check LWRP to create the check in the API.

The 'alarm' key for a check is very similar, and defines alarm tied to the given check.
At this time the configuration hash will create one alarm with multiple states, this is a change from v2 which created one alarm per state.
The 'alarm' key is itself a hash supporting the following keys:

| Key    | Value Data type | Description | Required | API Documentation Attribute Name | Default Value | Note |
| ------ | --------------- | ----------- | -------- | -------------------------------- | ------------- | ---- |
| disabled | Boolean | Disables the check when true | No | disabled | false | -- |
| metadata | Hash | Metadata to associate with the check | No | metadata | None |  |
| consecutive_count | Integer | Number of consecutive evaluations required to trigger a state change | No | consecutiveCount | node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['consecutive_count'] | Allowed values are 1 - 5 |
| notification_plan_id | string | Notification Plan ID to trigger on alarm | No | notification_plan_id | node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] | See [the API guide here](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-notification-plans.html) for details on notification plans |
| CRITICAL | Hash | CRITICAL state alarm data | No | -- | None | Takes a state data hash, see below |
| WARNING | Hash | WARNING state alarm data | No | -- | None | Takes a state data hash, see below |
| states | Array | Array of state data hashes to be added | No | -- | None | See below for a description |
| alarm_dsl | string | Explicit alarm DSL criteria for the alarm | No | criteria | None | Exclusive with CRITICAL, WARNING, and state |
| remove_old_alarms | Boolean | Remove alarms created by v2 of the cookbook | No | -- | node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['remove_old_alarms'] | Only removes CRITICAL and WARNING alarms, any custom states will need to be removed by hand. |

The states, CRITICAL, and WARNING are used to auto generate the alarm DSL criteria for the check.
CRITICAL and WARNING are present for convience and reverse compatability, and are equivalent to an entry in the states array with the corresponding state.
The add order for the alarm DSL is CRITICAL, WARNING, and then the entries in the state array.
The states take a 4th level hash ([yo-dawg](http://i.imgur.com/b18qXaT.jpg)) that describes the individual state:

| Key    | Value Data type | Description | Required | API Documentation Attribute Name | Default Value | Note |
| ------ | --------------- | ----------- | -------- | -------------------------------- | ------------- | ---- |
| conditional | string | Conditional logic to place in the alarm if() block | Yes | criteria | None | This implementation abstracts part of the criteria DSL, see below |
| disabled | Boolean | Disables the state when true | No | -- | false | Provided for compatability with v2 and simply omits the state logic from the criteria. Use of this option is discouraged |
| state | String | State value to use when building the criteria DSL value | Yes within the states array | -- | Label for CRITICAL and WARNING helpers | Should be CRITICAL, WARNING, or OK |
| message | String | Message to return when the conditional is met | No | -- | "#{check} is past #{state} threshold" | -- |

Note that several keys (alarm_dsl, metadata, notification_plan_id) which were previously supported within the state hash are now deprecated.
They should be moved down into the alarm hash itself to modify the, now single, alarm.

The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Alarms](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-alarms.html)

If alarm_dsl is specified then that value is used verbatim, no abstraction is performed.
Otherwise, the Monitoring alarm criteria is abstracted from the API somewhat.
The alarm threshold conditional will be used directly in the if() block.
The body of the criteria conditional is handled by the cookbook unless overridden.
A final OK state will automatically be added if alarm_dsl is not used.
See recipes/monitors.rb and libraries/MonitorsRecipeHelpers.rb for the exact abstraction and body used.

The values for each check is passed to the rackspace_cloudmonitoring_alarm LWRP to create the check in the API.
Also note that node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] does not have a default.
If 'alarm' is not defined any existing alarm will be removed.

Alarms may also be blanket disabled for the node, see the bypass_alarms option in attributes/default.rb

As mentioned above the monitoring entity will automatically be created or updated.
The entity behavior is configured by the following node variables:

| variable | Description |
| -------- | ----------- |
| default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['label']         | Label for the entity   |
| default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['ip_addresses']  | IP addresses to set in the API |
| default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_method'] | Method to use to search for existing entities |
| default['rackspace_cloudmonitoring']['monitors_defaults']['entity']['search_ip']     | IP to use when searching by IP |

Defaults for all are in attributes/default.rb.
See the entity Resource Provider description below for details about the search method.
For Rackspace Cloud Servers the defaults will result in the existing, automatically generated entity being reused.
Checks and Alarms need to reference the entity and will use the Chef label to do so.

### Configuration Hash Example

The following example configures CPU, load, disk, and filesystem monitors, with alarms enabled on the 5 minute load average:

```ruby
# Calculate default values
# Critical at x4 CPU count
cpu_critical_threshold = (node['cpu']['total'] * 4)
# Warning at x2 CPU count
cpu_warning_threshold = (node['cpu']['total'] * 2)

# Define our monitors
node.default['rackspace_cloudmonitoring']['monitors'] = {
  'cpu' =>  { 'type' => 'agent.cpu', },
  'load' => { 'type'  => 'agent.load_average',
    'alarm' => {
      'CRITICAL' => { 'conditional' => "metric['5m'] > #{cpu_critical_threshold}", },
      'WARNING'  => { 'conditional' => "metric['5m'] > #{cpu_warning_threshold}", },
    },
  },

  'disk' => {
    'type' => 'agent.disk',
    'details' => { 'target' => '/dev/xvda1'},
  },
  'root_filesystem' => {
    'type' => 'agent.filesystem',
    'details' => { 'target' => '/'},
  },

  'web_check' => {
    'type' => 'remote.http',
    'target_hostname' => node['fqdn'],
    'monitoring_zones_poll' => [
      'mzdfw',
      'mziad',
      'mzord'
    ],
    'details' => {
      "url" => "http://#{node['ipaddress']}/",
      "method" => "GET"
    }
  }
}

#
# Call the monitoring cookbook with our changes
#
include_recipe "rackspace_cloudmonitoring::monitors"
```

The previous example assumes that the API key and API username are set via the node attributes or a databag, and that node['rackspace_cloudmonitoring']['monitors_defaults']['alarm']['notification_plan_id'] is set.
It also assumes your system has a valid, fully qualified domain name.

NOTE: Earlier revisions assumed the check was of the "agent." type and automatically prepended "agent.".
This behavior has been removed to allow remote checks, the full name of the check must now be passed!

## Agent Recipe

The agent recipe installs the monitoring agent on the node.
It is called by the monitors recipe so the agent is installed automatically when using the method above.
With the API key and username set it is essentially standalone, it will call the agent_token LWRP to generate a token.

However, the following attributes can be set to bypass API calls and configure the agent completely from node attributes:

| Attribute | Description |
| --------- | ----------- |
| node['rackspace_cloudmonitoring']['config']['agent']['token'] | Agent Token |
| node['rackspace_cloudmonitoring']['config']['agent']['id']    | Agent ID    |

Note that BOTH must be set to bypass API calls.
The ID will be overwritten if only the token is passed.
See the API docs for exact details of these values.

The agent recipe also supports a configuration hash for pulling in plugins.
Plugin directories can be added to the node['rackspace_cloudmonitoring']['agent']['plugins'] hash to install plugins for the agent.
The syntax is node['rackspace_cloudmonitoring']['agent']['plugins'][cookbook] = directory and utilizes the remote_directory chef LWRP.
So to install a plugin at directory foo_dir in cookbook bar_book use:

    node.default['rackspace_cloudmonitoring']['agent']['plugins']['bar_book'] = 'foo_dir'

## Resource Provider Usage

This cookbook exposes Resource Providers (RPs) to operate on Monitoring API objects at a lower level.
Direct interaction with RPs is not required when using the monitors.rb argument hash method.
General precedence for the RPs are:

```
Alarm
 | Requires Check Label, Entity Chef Label
 |
 +-> Check
      | Requires Entity Chef Label
	  | 
	  +-> Entity
	       | (Optional) Uses Agent ID
		   |
		   +-> Agent Token
```

A key note is that the UID for an object in the Monitoring API is generated when the object is created.
So the API create action returns the unique identifier which must then be used from then on to reference the object.
This flows counter to Chef where you assign a unique label at creation, and use that label from then on.
The underlying library works to abstract this as much as possible, but it is beneficial to keep in mind, especially with entity objects.

All Resource Providers support the following actions:

| Action | Description | Default |
| ------ | ----------- | ------- |
| create | Will create an object if it doesn't exist, but WILL NOT modify existing objects | Yes |
| update_if_missing | Will create an object if it doesn't exist, and will converge existing objects if they do not match the current object |  |
| delete | Will remove an object if it exists |  |
| nothing | Does nothing (noop) | |

Also, note that you must include the default recipe before utilizing the RPs.
The default recipe handles mandatory library dependencies and the RPs will fail with Fog errors.

Minimal examples are provided, please note all assume the API credentials are set in the node attributes or a databag.

### Agent Token

This RP interacts with the API to create Agent tokens.

The RP itself is quite simple, it only takes one argument in addition to the label:

| Option | Description                  | Required | Note |
| ------ | -----------                  | -------- | ---- |
| token  | Monitoring agent token value | No       |      |

The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Agent Tokens](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-agent-tokens.html)
The label is the only updatable attribute, and the chef RP label is used for the API label.
Use of this provider is discouraged, utilize the agent recipe.

Example:

```
rackspace_cloudmonitoring_agent_token node['hostname'] do
   token               node['rackspace_cloudmonitoring']['config']['agent']['token']
end
```

### Entity

This RP interacts with the API to create, and delete entity API objects.

| Option | Description | Required | Note |
| ------ | ----------- | -------- | ---- |
| api_label     | Label to use for the label in the API | No | Defaults to the Chef RP label |
| metadata      | Metadata for the entity | No |  |
| ip_addresses  | IP addresses that can be referenced by checks on this entity. | No | See API docs |
| agent_id      | ID of the agent associated with his server | No |  |
| search_method | Method to use for locating existing entities | No | See below for details |
| search_ip     | IP to use for IP search | No | See below for details |
| search_id     | Entity ID to use for ID search | No | See below for details |
| rackspace_api_key | API key to use | No | See Credential Handling for further details |
| rackspace_username| API username to use | No | See Credential Handling for further details |
| rackspace_auth_url| API auth URL to use | No | See Credential Handling for further details |

The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Entities](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-entities.html)

Unfortunately the label is often not sufficient to locate a proper existing entity due to various factors.
For this, a number of search methods are provided to locate existing entities via the search_method attribute:

| Method | Key used | Matched to |
| ------ | -------- | ---------- |
| [default] | Chef RP label | API Label |
| ip      | search_ip argument | Any IP associated with the entity |
| id      | search_id argument | API ID |
| api_label | api_label argument | API Label |

ip is recommend as the easiest method.
id is the most reliable, but the id is not exposed outside of the underlying library.

Example:

```
rackspace_cloudmonitoring_entity node['hostname'] do
  agent_id      node['rackspace_cloudmonitoring']['config']['agent']['id']
  search_method 'ip'
  search_ip     node['ipaddress']
  ip_addresses  { default: node['ipaddress'] }
end
```

### Check

This RP interacts with the API to create, and delete check API objects.

| Option | Description | Required | Note |
| ------ | ----------- | -------- | ---- |
| entity_chef_label       | The Chef label of the entity to associate to | Yes |  |
| type                    | The type of check | Yes |See API docs |
| details                 | Details of the check | No |See API docs |
| metadata                | Metadata to associate with the check  | No | See API docs |
| period                  | The period in seconds for a check.  | No | Has restrictions, See API docs |
| timeout                 | The timeout in seconds for a check. | No | Has restrictions, See API docs |
| disabled                | Disables the check when true        | No | |
| target_alias            | (Remote Checks) Key in the entity's 'ip_addresses' hash used to resolve remote check to an IP address. | No | Has restrictions, See API docs |
| target_resolver         | (Remote Checks) Determines how to resolve the remote check target.  | No | See API docs |
| target_hostname         | (Remote Checks) The hostname remote check should target. | No | Has restrictions, See API docs |
| monitoring_zones_poll   | (Remote Checks) Monitoring zones to poll from for remote checks | No | See API Docs |
| rackspace_api_key | API key to use | No | See Credential Handling for further details |
| rackspace_username| API username to use | No | See Credential Handling for further details |
| rackspace_auth_url| API auth URL to use | No | See Credential Handling for further details |

The Chef label is used for the API label, which is used for searching.  Multiple checks on one entity with the same label in the API are NOT supported.
The vast majority of objects are passed through to the API.
The Entity RP for the associated entity object must have already been called.
The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Checks](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-checks.html)

Example:

```
rackspace_cloudmonitoring_check 'Load' do
  entity_chef_label node['hostname']
  type              'agent.load'
end
```

### Alarms

This RP interacts with the API to create, and delete alarm API objects.

| Option | Description | Required | Note |
| ------ | ----------- | -------- | ---- |
| entity_chef_label    | The Chef label of the entity to associate to | Yes |  |
| notification_plan_id | The Notification plan to use for this alarm | Yes | See [the API guide here](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-notification-plans.html) for details on notification plans |
| check_id             | API ID of the underlying check | No | check_id or check_label is required |
| check_label          | Label of the underlying check  | No | check_id or check_label is required |
| criteria             | Alarm Criteria | No | See API docs, cannot be used with example criteria |
| metadata             | Metadata to associate with the check  | No | See API docs |
| disabled                | Disables the check when true        | No | |
| example_id           | Example criteria ID | No | See API docs, cannot be used with criteria
| example_values       | Example criteria values | When using example_id | See API docs |
| rackspace_api_key | API key to use | No | See Credential Handling for further details |
| rackspace_username| API username to use | No | See Credential Handling for further details |
| rackspace_auth_url| API auth URL to use | No | See Credential Handling for further details |

The Chef label is used for the API label, which is used for searching.  Multiple alarms on one ENTITY (not check) with the same label in the API are NOT supported.
The vast majority of objects are passed through to the API.
The Check and Entity RPs for the associated check and entity object must Hanover already been called.
The API documentation can be found here: [Rackspace Cloud Monitoring Developer Guide: Alarms](http://docs.rackspace.com/cm/api/v1.0/cm-devguide/content/service-alarms.html)

Example, note that the Notification Plan ID must be set to a valid value:

```
rackspace_cloudmonitoring_alarm  "Load Critical Alarm" do
  entity_chef_label    node['hostname']
  check_label          'Load'
  criteria             "if (metric['5m'] > 8) { return CRITIAL, 'Load is past Critical threshold' }"
  notification_plan_id 'Put Plan ID Here'
end
```

### Resource Provider Tests

ChefSpec matchers are provided and defined in libraries/matchers.rb

License & Authors
-----------------
- v2.0.0 Author: Tom Noonan II (<thomas.noonan@rackspace.com>)

```
Copyright:: 2012 - 2014 Rackspace

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
