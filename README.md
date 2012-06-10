Description
===========

This cookbook provides automated way to manage the various resources using the Rackspace Cloud Monitoring API.
Specifically this recipe will focus on main atom's in the system.

* Entities
* Checks
* Alarms
* Agents (soon)
* Agent Tokens (soon)


Requirements
============

Requires Chef 0.7.10 or higher for Lightweight Resource and Provider support. Chef 0.8+ is recommended. While this
cookbook can be used in chef-solo mode, to gain the most flexibility, we recommend using chef-client with a Chef Server.

The inner workings of the library depend on [fog](https://github.com/fog/fog) which is used by the Ruby command line
client called [rackspace-monitoring-rb](https://github.com/racker/rackspace-monitoring-rb).  These are handled in the
instantiation and use of the Cookbook.

A Rackspace Cloud Hosting account is required to use this tool.  And a valid `username` and `api_key` are required to
authenticate into your account.

You can get one here [sign-up](https://cart.rackspace.com/cloud/?cp_id=cloud_monitoring).


Attributes
==========

All attributes are namespaced under the `node[:cloud_monitoring]` namespace.  This keeps everything clean and organized.

Usage
=====

This cookbook exposes many different elements of the Cloud Monitoring product.  The first element is the `Entity`.  The
`Entity` maps to the target of what you're monitoring.  This in most cases represents a server, loadbalancer or website.
However, there is some flexibility but that is generally exposed only in doing something more advanced.  The first use
case we will show is populating your chef nodes in Cloud Monitoring...

```ruby
cloud_monitoring_entity "#{node.hostname}" do
  ip_addresses        'default' => node[:ipaddress]
  metadata            'environment' => 'dev', :more => 'meta data'
  rackspace_username  'joe'
  rackspace_api_key   'XXX'
  action :create
end
```

This operation is idempotent, and will select the node based on the name of the resource, which maps to the label of the
entity.  If an attribute of the resource changes the provider will issue a `PUT` instead of a `POST` to update the
resource instead of creating another one.

This will set an attribute on the node `node[:cloud_monitoring][:entity_id]`.  This attribute will be saved in the
chef server.  It is bi-directional, it can re-attach your cloud monitoring entities to your chef node based on the
label.  Keep in mind nothing is removed unless explicitly told so, which is idiomatic chef.
