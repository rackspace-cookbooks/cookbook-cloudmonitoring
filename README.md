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

