rackspace_cloudmonitoring Unit Tests
====================================

As this cookbook primarily interacts with the API and not the underlying system the vast majority of testing is done via unit tests.
As the libraries of this cookbook were designed to be modular; there is little end-to-end testing here by design.
End-to-end testing is intended to be handled by the Test Kitchen integration tests which actually runs Chef (albeit with Fog mocked).
The tests here are intended to provide heavy coverage of the library under test and that it's API consumed by higher level classes behave as expected.
As such tests will frequently mock or stub out underlying classes for testing as the test is only designed to cover that one class, excluding the classes below it.

See libraries/README.md for details on the libraries being tested and some of the dividing lines.

