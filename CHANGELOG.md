v3.1.2
------
* Add support for Fog/API pagination.  Resolves >100 object bug (#31)

v3.1.0
------
* Add alarm disable feature

v3.0.0
------
* Refactor monitors.rb alarm generation which is not completely backwards compatable.

v2.1.0
------
* Alter naming of alarms that could result in duplicates

v2.0.0
------
* Refactor cloud_monitoring library to use classes and object-oriented methodology
* Change the Entities LWRP to allow search criteria, deprecating the entities.rb recipe
* Change check and alarm LWRPs to use the Chef label for the associated entity, deprecate the entity_id and entity_label arguments
* Add delete functionality to the LWRPs
* Modify the configuration hash to not prepend "agent." to the checks
* Add functionality to the config hash
* Modify node attribute namespace to meet rackspace-cookbooks standards
* General code cleanup and style changes
* Added tests

v1.1.0
------
* Add entity.rb to auto-select an existing entity by IP (Credit to Thomas Cate for this code)
* Add monitors.rb to configure monitors from a configuration hash

v1.0.1
------
* Switch to Fog gem from rackspace-monitoring gem. Fog 1.1.15 or higher is required.
* Usage of the chef_gem resource now required.

v0.2.5
------
