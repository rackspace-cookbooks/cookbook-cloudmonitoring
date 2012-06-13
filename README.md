# Description

This cookbook provides automated way to manage the various resources using the Rackspace Cloud Monitoring API.
Specifically this recipe will focus on main atom's in the system.

* Entities
* Checks
* Alarms
* Agents (soon)
* Agent Tokens (soon)


# Requirements

Requires Chef 0.7.10 or higher for Lightweight Resource and Provider support. Chef 0.8+ is recommended. While this
cookbook can be used in chef-solo mode, to gain the most flexibility, we recommend using chef-client with a Chef Server.

The inner workings of the library depend on [fog](https://github.com/fog/fog) which is used by the Ruby command line
client called [rackspace-monitoring-rb](https://github.com/racker/rackspace-monitoring-rb).  These are handled in the
instantiation and use of the Cookbook.

A Rackspace Cloud Hosting account is required to use this tool.  And a valid `username` and `api_key` are required to
authenticate into your account.

You can get one here [sign-up](https://cart.rackspace.com/cloud/?cp_id=cloud_monitoring).


# Attributes

All attributes are namespaced under the `node[:cloud_monitoring]` namespace.  This keeps everything clean and organized.

# Usage

This cookbook exposes many different elements of the Cloud Monitoring product. We'll go over some examples and best
practices for using this cookbook. The most interesting pieces are the three core Resources in the system `Entity`,
`Check` and `Alarm`. So we'll cover those first and tackle The other primitives towards the end.

## Entity

The first element is the `Entity`.  The `Entity` maps to the target of what you're monitoring.  This in most cases
represents a server, loadbalancer or website.  However, there is some advanced flexibility but that is only used in rare
cases. The first use case we will show is populating your chef nodes in Cloud Monitoring...

Learn more about all these concepts in the docs and specifically the
[Concepts](http://docs.rackspacecloud.com/cm/api/v1.0/cm-devguide/content/concepts-key-terms.html) section of the
developer guide.

```ruby
cloud_monitoring_entity "#{node.hostname}" do
  ip_addresses        'default' => node[:ipaddress]
  metadata            'environment' => 'dev', :more => 'meta data'
  rackspace_username  'joe'
  rackspace_api_key   'XXX'
  action :create
end
```
If you looked in the Rackspace Cloud Monitoring API /entities on your account you'd see an `Entity` labeled whatever the
hostname of the machine which executed this chef code.

Most of the fields are optional, you can even specify something as minimal as:

```ruby
cloud_monitoring_entity "#{node.hostname}" do
  rackspace_username  'joe'
  rackspace_api_key   'XXX'
  action :create
end
```

This operation is idempotent, and will select the node based on the name of the resource, which maps to the label of the
entity.  This is ***important*** because this pattern is repeated through out this cookbook.  If an attribute of the
resource changes the provider will issue a `PUT` instead of a `POST` to update the resource instead of creating another
one.

This will set an attribute on the node `node[:cloud_monitoring][:entity_id]`.  This attribute will be saved in the
chef server.  It is bi-directional, it can re-attach your cloud monitoring entities to your chef node based on the
label.  Keep in mind nothing is removed unless explicitly told so, like most chef resources.


## Check

The check is the way to start collecting data.  The stanza looks very similar to the `Entity` stanza except the accepted
parameters are different, it is seen more as the "what" of monitoring.

***Note: you must either have the attribute assigned `node[:cloud_monitoring][:entity_id]` or pass in an entity_id
explicitly so the Check knows which node to create it on.***

Here is an example of a ping check:

```ruby
cloud_monitoring_check  "ping" do
  target_alias          'default'
  type                  'remote.ping'
  period                30
  timeout               10
  monitoring_zones_poll ['mzord']
  rackspace_username    'joe'
  rackspace_api_key     'XXX'
  action :create
end
```

This will create a ping check that is scoped on the `Entity` that was created above.  In this case, it makes sense,
however sometimes you want to be specific about which node to create this check on.  If that's the case, then passing in
an `entity_id` will allow you to do that.

This block will create a ping check named "ping" with 30 second interval from a single datacenter "mzord".  It will
execute the check against the target_alias default, which is the chef flagged ipaddress above.

Creating a more complex check is just as simple, take HTTP check as an example.  There are multiple options to pass in
to run the check. This maps very closely to the API, so you have a details hash at your disposal to do that.

```ruby
cloud_monitoring_check  "http" do
  target_alias          'default'
  type                  'remote.http'
  period                30
  timeout               10
  details               'url' => 'http://www.google.com', 'method' => 'GET'
  monitoring_zones_poll ['mzord', 'mzdfw']
  rackspace_username    'joe'
  rackspace_api_key     'XXX'
  action :create
end
```

## Alarm

The `Alarm` is the way to specify a threshold in Cloud Monitoring and connect
that to sending an alert to a customer.  Without an `Alarm` you could never get
an email even if the check was in a failing state. 
