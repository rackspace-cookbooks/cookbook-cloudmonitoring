# encoding: UTF-8
actions :create, :update, :delete
default_action :update

attribute :label, kind_of:  String, name_attribute:  true
attribute :check_id, kind_of:  String
attribute :metadata, kind_of:  Hash
attribute :criteria, kind_of:  String
attribute :notification_plan_id, kind_of:  String, required:  true
attribute :entity_chef_label, kind_of:  String, required:  true
attribute :disabled, kind_of: [TrueClass, FalseClass]

attribute :example_id, kind_of:  String
attribute :example_values, kind_of:  Hash

attribute :check_label, kind_of:  String

attribute :rackspace_api_key, kind_of:  String
attribute :rackspace_username, kind_of:  String
attribute :rackspace_auth_url, kind_of:  String
