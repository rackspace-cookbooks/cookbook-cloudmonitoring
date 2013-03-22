actions :create, :delete

attribute :label, :kind_of => String, :name_attribute => true
attribute :check_type, :kind_of => String
attribute :check_id, :kind_of => String
attribute :metadata, :kind_of => Hash
attribute :criteria, :kind_of => String
attribute :notification_plan_id, :kind_of => String
attribute :entity_id, :kind_of => String
attribute :entity_label, :kind_of => String

attribute :example_id, :kind_of => String
attribute :example_values, :kind_of => Hash

attribute :check_label, :kind_of => String

attribute :rackspace_api_key, :kind_of => String
attribute :rackspace_username, :kind_of => String
