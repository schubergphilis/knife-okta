# knife-okta CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to [Semantic Versioning](http://semver.org/).

## 0.1.2 (2018-03-07)

### Fixed

* Fix returned group hash - previously the first group that matched the name was returned, now we only return groups with `:type => okta_group`
* Fix how changes are displayed:
  * New and old data bags will be correctly compared
  * Now caching the data bag response to speed things up a bit

## 0.1.1 (2018-02-06)

### Fixed

* Fix test for multiple group parsing, comma separated value wasn't not being split
* Fix returned list to contain unique values
* Fix rubocop warning for Codacy

## 0.1.0 (2018-02-01)

First release.
