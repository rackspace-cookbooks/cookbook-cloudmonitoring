# Agent.rb: serverspec file for testing the agent recipe

require 'spec_helper'

# If the repo is broken the agent won't install
# If the config is missing the agent won't start
# Currently no check if the agent registers and is connecting to the API, but in
#   its current form we can feed it dummy data and not worry about account pollution.
describe 'Server With CloudMonitoring Agent' do
  it 'should have the agent running' do
    expect(service 'rackspace-monitoring-agent').to be_running
    expect(service 'rackspace-monitoring-agent').to be_enabled
  end
end
