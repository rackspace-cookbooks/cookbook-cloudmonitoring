rackspace_cloudmonitoring libraries
===================================

This cookbook has multiple tiers of libraries:

* HWRPs
* Classes supporting recipes and the HWRPs that interact with the API
* Test support libraries

HWRPs
-----

HWRPs were used instead of LWRPs as it easily enabled testing with RSpec.

| File | Purpose |
| ---- | ------- |
| agent_token_hwrp.rb | Provides the rackspace_cloudmonitoring_agent_token resource provider |
| alarm_hwrp.rb       | Provides the rackspace_cloudmonitoring_alarm resource provider |
| check_hwrp.rb       | Provides the rackspace_cloudmonitoring_check resource provider |
| entity_hwrp.rb      | Provides the rackspace_cloudmonitoring_entity resource provider |

Support Classes
---------------

A number of underlying classes are used to interact with the API and wrap monitoring (MaaS) objects to simplify the HWRP code

### Classes representing MaaS objects

These classes are used directly by the HWRPs

| Class | File | Purpose |
| ----- | ---- | ------- |
| CmAgentToken | CMAgentToken.rb | Class for interacting with Agent Token Objects |
| CMAlarm | CMAlarm.rb | Class for interacting with Alarm objects |
| CMCheck | CMCheck.rb | Class for interacting with Check objects |
| CMEntity | CMEntity.rb | Class for interacting with Entity objects |

Note that the naming of the CMEntity member methods differs slightly from the other classes.
This is legacy naming from an earlier revision where CMAlarm and CMCheck inherited CMEntity, but that behavior was deprecated.

### Underlying support classes

These classes support the CM Classes above

| Class | File | Purpose |
| ----- | ---- | ------- |
| CMApi | CMApi.rb | This class wraps Fog and creates the API object utilized by other classes.  It handles API connections and mocking. |
| CMCache | CMCache.rb | This class implements a in-memory cache object used by higher level classes.  This behavior is required as newly created objects are not immediately available in the API and it cuts down on redundant API calls. |
| CMCredentials | CMCredentials.rb | This class handles API credential sourcing and precedence from the HWRP attributes, node attributes, and databag in a common and consistent manner |
| CMObjBase | CMObjBase.rb | This is a common class implementing the basic actions required to interact with MaaS objects.  It is inherited by the higher level classes and serves to deduplicate code. |
| CMChild | CMChild.rb | This is a common class for CMAlarm and CMCheck objects, which are incredibly similar.  It implements the shared behavior and entity loading for CMCheck and CMAlarm objects, and is inherited by both. |

#### Pagination Warning
The MaaS APIs paginatate and this is passed through Fog.
Requests to the API may not return the entire dataset.
Opscode::Rackspace::Monitoring::CMObjBase.paginated_find resolves this for find() calls.
Other API gets must handle pagination otherwise undefined behavior could result.

### Recipe support libraries

The following libraries implement methods to support the specified recipes:

| Module | File | Supported Recipe |
| ------ | ---- | ---------------- |
| MonitorsRecipeHelpers | MonitorsRecipeHelpers.rb | monitors |

Testing Classes
---------------

These classes are for testing and are not used under normal operation

| File | Purpose |
| ---- | ------- |
| matchers.rb | Implements custom ChefSpec matchers for the HWRPs. |
| mock_data.rb | Implements the MockMonitoring class which mimics Fog in memory for testing.  This class is loaded by CMApi when CMApi.mock! is enabled.  Mocking is also enabled by the mocking credential handled through CMCredentials. |

Note that mock_data was created as Fog mocks are currently not stateful, which impedes our testing.
There is also some turbulence around the status of Fog mocks, so a mocking system independent of the underlying Fog library was desired.
