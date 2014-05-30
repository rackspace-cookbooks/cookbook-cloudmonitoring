if defined?(ChefSpec)
    def create_cm_agent_token(resource_name)
      ChefSpec::Matchers::ResourceMatcher.new(:cloud_monitoring_agent_token, :create, resource_name)
    end

    def delete_cm_agent_token(resource_name)
      ChefSpec::Matchers::ResourceMatcher.new(:cloud_monitoring_agent_token, :delete, resource_name)
    end

    def create_cm_alarm(resource_name)
      ChefSpec::Matchers::ResourceMatcher.new(:cloud_monitoring_alarm, :create, resource_name)
    end

    def create_cm_check(resource_name)
      ChefSpec::Matchers::ResourceMatcher.new(:cloud_monitoring_check, :create, resource_name)
    end

    def create_cm_entity(resource_name)
      ChefSpec::Matchers::ResourceMatcher.new(:cloud_monitoring_entity, :create, resource_name)
    end

    def delete_cm_entity(resource_name)
      ChefSpec::Matchers::ResourceMatcher.new(:cloud_monitoring_entity, :delete, resource_name)
    end
end

