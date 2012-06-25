# netapp module
Warning: This is not yet functional, don't bother downloading it. :)

## TODO

The following items encapsulate most of my use case
* Support adding/deleting/modifying nfs exports
* Support creating/deleting/updating volumes and qtrees
* quota support

Currently depending on the ruby libraries from Netapp Manageability SDK, which are not redistributable.

It shouldn't be too hard to add other features if there's a demand
* Data Fabric Manager support
* Support adding/deleting/modifying cifs shares
* Local user support
* LDAP and/or AD configuration
* ???

Structure, layout and basic concepts shamelessly stolen from the [puppetlabs/f5](https://github.com/puppetlabs/puppetlabs-f5) module

