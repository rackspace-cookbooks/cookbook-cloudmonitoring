actions :create, :delete

attribute :label, :kind_of => String, :name_attribute => true
attribute :check_type, :kind_of => String
attribute :check_id, :kind_of => String
attribute :metadata, :kind_of => Hash
attribute :notification_plan_id, :kind_of => String, :required => true
attribute :entity_id, :kind_of => String

attribute :example_id, :kind_of => String
attribute :example_values, :kind_of => Hash

attribute :check_label, :kind_of => String

attribute :rackspace_api_key, :kind_of => String
attribute :rackspace_username, :kind_of => String

def criteria(crit=nil, &block)
  # This gets run twice for a resource and the second time everything is nil
  # Therefore we check for the block and set that
  if block_given?
    require 'docile'
    @criteria = Docile.dsl_eval(Rackspace::CloudMonitoring::MonitoringCriteria.new, &block).to_s
  # Or we just leave it assigned
  elsif @criteria
    @criteria
  # Or we assign it to whatever crit is
  else
    @criteria = crit
  end
end