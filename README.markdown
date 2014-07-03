# NetApp network device module

**Please note that the device configuration management has been changed as of v0.4.0 of this module.
You will therefore need to update your device configuration file if upgrading from a version < 0.4.0.**

**Table of Contents**

- [NetApp network device module](#netapp-network-device-module)
	- [Overview](#overview)
	- [Features](#features)
	- [Requirements](#requirements)
		- [NetApp Manageability SDK](#netapp-manageability-sdk)
		- [NetApp user](#netapp-user)
	- [Usage](#usage)
		- [Device Setup](#device-setup)
		- [NetApp operations](#netapp-operations)
	- [Contributors](#contributors)
	- [TODO](#todo)
	- [Development](#development)
		- [Testing](#testing)

## Overview
The NetApp network device module is designed to add support for managing NetApp filer configuration using Puppet and its Network Device functionality.

The Netapp network device module has been written and tested against NetApp OnTap 8.0.4 7-mode.
However it may well be compatible with other OnTap versions.

## Features
The following items are supported:

 * Creation, modification and deletion of volumes, including auto-increment, snapshot schedules and volume options.
 * Creation, modification and deletion of QTrees.
 * Creation, modification and deletion of NFS Exports, including NFS export security.
 * Creation, modification and deletion of users, groups and roles.
 * Creation, modification and deletion of Quotas.
 * Creation of snapmirror relationships.
 * Creation of snapmirror schedules.

## Requirements
Since we can not directly install a puppet agent on the NetApp filers, it can either be managed from the Puppet Master server,
or through an intermediate proxy system running a puppet agent. The requirement for the proxy system:

 * Puppet 2.7.+
 * NetApp Manageability SDK Ruby libraries

### NetApp Manageability SDK
The NetApp Ruby libraries are contained within the NetApp Manageability SDK, currently at v5.0, which is available to download directly from [NetApp](http://support.netapp.com/NOW/cgi-bin/software?product=NetApp+Manageability+SDK&platform=All+Platforms).
Please note you need a NetApp NOW account in order to be able to download the SDK.

Once you have downloaded and extracted the SDK, the following files need to be copied onto your Puppet Master:
`../lib/ruby/NetApp > [module dir]/netapp/lib/puppet/util/network_device/netapp/`

Once the files have been copied into place on your Puppet Master, a patch needs to be applied to *NaServer.rb*.
The patch file can be found under `files/NaServer.patch`.
To apply, change into the `netapp` module root directory and run:

	patch lib/puppet/util/network_device/netapp/NaServer.rb < files/NaServer.patch

This should apply the patch without any errors, as below:

	$ patch lib/puppet/util/network_device/netapp/NaServer.rb < files/NaServer.patch
	patching file lib/puppet/util/network_device/netapp/NaServer.rb
	$

### NetApp user

If you want to access the NetApp filer with a dedicated user (recommended), you have to create a role with the following capabilities:

* *Basic capabilities* (you will not be able to use the module without these)  
  `login-http-admin`, `api-system-get-version`, `api-system-get-info`, `api-options-get`, `api-net-ifconfig-get`
* If you intend to manage a virtual filer through a physical filer, instead of connecting to the virtual filer directly, you need to have the following capability:  
  `security-api-vfiler`
* To be able to use the *netapp\_export* type you need the following capabilities:  
  `api-nfs-exportfs-append-rules-2`, `api-nfs-exportfs-delete-rules`, `api-nfs-exportfs-list-rules-2`, `api-nfs-exportfs-modify-rule-2`
* To be able to use the *netapp\_group* type you need the following capabilities:  
  `api-useradmin-group-add`, `api-useradmin-group-delete`, `api-useradmin-group-list`, `api-useradmin-group-modify`
* To be able to use the *netapp\_qtree* type you need the following capabilities:  
  `api-qtree-create`, `api-qtree-delete`, `api-qtree-list`
* To be able to use the *netapp\_quota* type you need the following capabilities:  
  `api-quota-add-entry`, `api-quota-delete-entry`, `api-quota-list-entries`, `api-quota-modify-entry`, `api-quota-off`, `api-quota-on`, `api-quota-resize`, `api-quota-status`  
* To be able to use the *netapp\_role* type you need the following capabilities:  
  `api-useradmin-role-add`, `api-useradmin-role-delete`, `api-useradmin-role-list`, `api-useradmin-role-modify`
* To be able to use the *netapp\_snapmirror* type you need the following capabilities:  
  `api-snapmirror-get-status`, `api-snapmirror-initialize`  
* To be able to use the *netapp\_snapmirror_schedule* type you need the following capabilities:
  `api-snapmirror-list-schedule`, `api-snapmirror-set-schedule`  
* To be able to use the *netapp\_user* type you need the following capabilities:  
  `api-useradmin-user-add`, `api-useradmin-user-delete`, `api-useradmin-user-list`, `api-useradmin-user-modify`
* To be able to use the *netapp\_volume* type you need the following capabilities:  
  `api-snapshot-get-schedule`, `api-snapshot-set-reserve`, `api-snapshot-set-schedule`, `api-volume-autosize-set`, `api-volume-create`, `api-volume-destroy`, `api-volume-list-info`, `api-volume-offline`, `api-volume-online`, `api-volume-options-list-info`, `api-volume-restrict`, `api-volume-set-option`, `api-volume-size`

Let's say you only want to manage quotas with puppet and you want to limit the user's rights to the *netapp\_quota* type. You can now create a role for that purpose, add the role to a new group `puppet_group` and add a new user `puppet` to that group:

    useradmin role add puppet_role -a login-http-admin,security-api-vfiler,api-system-get-version,api-system-get-info,api-options-get,api-net-ifconfig-get,api-quota-list-entries,api-quota-add-entry,api-quota-delete-entry,api-quota-modify-entry,api-quota-resize,api-quota-off,api-quota-on,api-quota-status
    useradmin group add puppet_group -r puppet_role
    useradmin user add puppet -g puppet_group

The last step will ask you to assign a password to the new user `puppet`. You can now setup `puppet device` to use the specified user and password to access your NetApp device (see next section)

## Usage

### Device Setup
In order to configure a NetApp network device, the device *type* should be `netapp`.
You can either configure the device within */etc/puppet/device.conf* or, preferrably, create an individual config file for each device within a subfolder.
This is preferred as it allows you to run puppet against individual devices, rather than all devices configured...

In order to run puppet against a single device, you can use the following command:

    puppet device --deviceconfig /etc/puppet/device/[device].conf

Example configuration `/etc/puppet/device/pfiler01.example.com.conf`:

    [pfiler01.example.com]
      type netapp
      url https://root:secret@pfiler01.example.com

You can also specify a virtual filer you want to operate on: Simply
provide the connection information for your physical filer and specify
an optional path that represents the name of your virtual filer. Example
configuration `/etc/puppet/device/vfiler01.example.com.conf`:

    [vfiler01.example.com]
      type netapp
      url https://root:secret@pfiler01.example.com/vfiler01

### NetApp operations
As part of this module, there is a defined type called 'netapp::vqe', which can be used to create a volume, add a qtree and create an NFS export.
An example of this is:

    netapp::vqe { 'volume_name':
      ensure         => present,
      size           => '1t',
      aggr           => 'aggr2',
      spaceres       => 'volume',
      snapresv       => 20,
      autoincrement  => true,
      persistent     => true
    }

This will create a NetApp volume called `v_volume_name` with a qtree called `q_volume_name`.
The volume will have an initial size of 1 Terabyte in Aggregate aggr2.
The space reservation mode will be set to volume, and snapshot space reserve will be set to 20%.
The volume will be able to auto increment, and the NFS export will be persistent.

You can also use any of the types individually, or create new defined types as required.

## Contributors
Thanks to the following people who have helped with this module:
 * Stefan Schulte

## TODO
The following items are yet to be implemented:

 * Data Fabric Manager support
 * Support adding/deleting/modifying cifs shares
 * LDAP and/or AD configuration
 * ???

## Development

The following section applies to developers of this module only.

### Testing

You will need to install the NetApp Manageability SDK Ruby libraries for most of the tests to work.
How to obtain these files is detailed in the NetApp Manageability SDK section above.
