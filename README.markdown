# NetApp network device module

**N.B. Please note that this module is no longer being maintained.   
For the supported version, please see the [Puppetlabs-NetApp](https://forge.puppetlabs.com/puppetlabs/netapp)**

[![Coverage Status](https://coveralls.io/repos/fatmcgav/fatmcgav-netapp/badge.png?branch=develop)](https://coveralls.io/r/fatmcgav/fatmcgav-netapp?branch=develop)

**Table of Contents**

- [NetApp network device module](#netapp-network-device-module)
	- [Overview](#overview)
	- [Features](#features)
	- [Requirements](#requirements)
		- [NetApp Manageability SDK](#netapp-manageability-sdk)
	- [Usage](#usage)
		- [Device Setup](#device-setup)
		- [NetApp operations](#netapp-operations)
		- [Type/Provider Support](#type/provider-support)
	- [Contributors](#contributors)
	- [TODO](#todo)
	- [Development](#development)
		- [Testing](#testing)

## Overview
The NetApp network device module is designed to add support for managing NetApp filer configuration using Puppet and its Network Device functionality.

The Netapp network device module has been written and tested against NetApp ONTAP 8.0.4 7-mode and NetApp ONTAP 8.2 C-Mode
However it may well be compatible with other ONTAP versions.

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

Once the files have been copied into place on your Puppet Master, a patch needs to be applied to *NaServer.rb* and *NaElement.rb*.  
The patches can be found under the `files` directory.  
To apply, change into the `netapp` module root directory and run:
	
	patch lib/puppet/util/network_device/netapp/NaServer.rb < files/NaServer.patch
	patch lib/puppet/util/network_device/netapp/NaElement.rb < files/NaElement.patch

This should apply the patch without any errors, as below:

	$ patch lib/puppet/util/network_device/netapp/NaServer.rb < files/NaServer.patch
	patching file lib/puppet/util/network_device/netapp/NaServer.rb
	$ patch lib/puppet/util/network_device/netapp/NaElement.rb < files/NaElement.patch
	patching file lib/puppet/util/network_device/netapp/NaElement.rb
	$
	

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

You can also specify a virtual filer or vserver you want to operate on: Simply
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

### Type/Provider Support
This module supports both NetApp filers operating in both 7-Mode and Cluster-Mode. The table below outlines what modes are supported by what types/providers. 

Resource | 7-Mode supported | CMode supported
--- | --- | ---
netapp_aggregate | No | Yes
netapp_cluster_id | No | Yes
netapp_cluster_peer | No | Yes
netapp_export_policy | No | Yes
netapp_group | Yes | No
netapp_igroup | No | Yes
netapp_license | No | Yes
netapp_lif | No | Yes
netapp_lun | No | Yes
netapp_lun_map | No | Yes
netapp_nfs_export | Yes | No
netapp_notify | Yes | Yes
netapp_qtree | Yes | Yes
netapp_quota | Yes | Yes
netapp_role | Yes | No
netapp_snapmirror | Yes | Yes
netapp_user | Yes | No
netapp_volume | Yes | Yes
netapp_vserver | No | Yes
netapp_vserver_option | No | Yes

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
