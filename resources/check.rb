# encoding: UTF-8
actions :create, :delete
default_action :create

attribute :label, kind_of: String, name_attribute: true
attribute :type, kind_of: String
attribute :details, kind_of: Hash
attribute :metadata, kind_of: Hash
attribute :target_alias
attribute :target_resolver
attribute :target_hostname
attribute :period, kind_of: Integer
attribute :timeout, kind_of: Integer
attribute :disabled, kind_of: [TrueClass, FalseClass]
attribute :monitoring_zones_poll, kind_of: Array
attribute :entity_chef_label, kind_of: String, required: true
attribute :disabled, kind_of: [ TrueClass, FalseClass ]

attribute :rackspace_api_key, kind_of: String
attribute :rackspace_username, kind_of: String
attribute :rackspace_auth_url, kind_of: String
