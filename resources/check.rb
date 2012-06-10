actions :create, :update, :disable, :delete

attribute :label, :kind_of => String, :name_attribute => true
attribute :type, :kind_of => String
attribute :details, :kind_of => Hash
attribute :metadata, :kind_of => Hash
attribute :target_alias
attribute :target_resolver
attribute :target_hostname
attribute :period, :kind_of => Integer
attribute :timeout, :kind_of => Integer
attribute :disabled, :kind_of => [TrueClass, FalseClass]
attribute :monitoring_zones_poll, :kind_of => Array
