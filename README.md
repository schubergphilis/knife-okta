# knife-okta

[![Build Status](https://travis-ci.org/schubergphilis/knife-okta.svg?branch=master)](https://travis-ci.org/schubergphilis/knife-okta)
[![Gem](https://img.shields.io/gem/v/knife-okta.svg)](https://rubygems.org/gems/knife-okta)

knife-okta is a knife plugin to interact with the Okta API.

The initial use case is to create data bags based on Okta group membership.

## Installation

As with all knife plugins, just install the gem:

```
gem install knife-okta
```

Or if you use ChefDK:

```
chef gem install knife-okta
```

## Usage

This plugin works the same as the `knife data bag from file` sub command, but instead queries Okta for a group's active members:

```
knife data bag from okta group BAG ITEM GROUP [GROUP..] (options)
```

The following parameters are added with this sub command:

```
        --max-change MAX_CHANGE             Set the maximum amount of allowed changes
    -a, --okta-attribute OKTA_ATTRIBUTE     Specify the user profile attribute to return
    -o, --okta-endpoint  OKTA_ENDPOINT      Set the Okta API endpoint (e.g. https://yourorg.okta.com/api/v1)
    -t, --okta-token OKTA_TOKEN             Set the Okta API token
        --show-changes                      Show any changes when uploading a data bag item
        --show-members                      Show data bag item members when uploading a data bag item

```

You can also add Okta options to your knife config file:

```
knife[:okta_attribute] = 'login'
knife[:okta_endpoint]  = 'https://myorg.okta-emea.com/api/v1'
knife[:okta_token]     = '004zNgntseobUzztBLSraij...'
```

## Examples

These examples assume the Okta configuration has been set in your knife config file.

### Create a data bag item from a single Okta group

To create a data bag called `users` with a data bag item called `linux_admins` that contains the display names of the group members:

```
knife data bag from okta group users linux_admins Linux-Admins -a displayName
```

* The `-a` option determines which profile attribute to populate the data bag with, at this time only `displayName`, `email` and `login` are supported.

### Create a data bag item from multiple Okta groups

You can specify multiple groups by providing a comma separated value:

```
knife data bag from okta group users admins Linux-Admins,Windows-Admins -a displayName
```

You can also provide Okta group names that contain spaces:

```
knife data bag from okta group users admins "Linux-Admins,Windows-Admins,Other Admins" -a displayName
```

### Limiting amount of changes

In the case where you want not upload a data bag if there more changes than expected (e.g. if running this plugin via a cron job), you can use the `--max-change` attribute:

```
knife data bag from okta group users linux_admins Linux-Admins -a displayName --max-change 5
```

This attribute watches for additions and removes, so using our example above if there were 3 additions and 2 removals then the data bag would not be uploaded as it met the threshold set (5).

## License

```
Copyright 2018 Stephen Hoekstra <shoekstra@schubergphilis.com>
Copyright 2018 Schuberg Philis

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## Contributing

We welcome contributed improvements and bug fixes via the usual work flow:

1. Fork this repository
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create a new pull request
