# NetApp network device module

**Please note that the device configuration management of NetApp network device module has been modified in the version 0.4.0. 
Therefore, if you are upgrading from a version lower than 0.4.0, you need to update your device configuration file**

**Table of Contents**

- [NetApp network device module](#netapp-network-device-module)
	- [Overview](#overview)
	- [Features](#features)
	- [Requirements](#requirements)
		- [NetApp Manageability SDK](#netapp-manageability-sdk)
	- [Usage](#usage)
		- [Device Setup](#device-setup)
		- [NetApp operations](#netapp-operations)
	- [Contributors](#contributors)
	- [TODO](#todo)
	- [Development](#development)
		- [Testing](#testing)

## Overview
The NetApp network device module is designed to add support for managing NetApp filer configuration using Puppet and its Network Device functionality.

The NetApp network device module has been written and tested against NetApp OnTap 8.0.4 7-mode.
However, it may be compatible with other OnTap versions.

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
Because we can not directly install a puppet agent on the NetApp filers, the agent can be managed either from the Puppet Master server or
through an intermediate proxy system running a puppet agent. The following are the requirements for the proxy system:

 * Puppet 2.7.+
 * NetApp Manageability SDK Ruby libraries

### NetApp Manageability SDK
The NetApp Ruby libraries are contained within the NetApp Manageability SDK, currently in v5.0. The libraries are available for download, directly from [NetApp](http://support.netapp.com/NOW/cgi-bin/software?product=NetApp+Manageability+SDK&platform=All+Platforms).
Please note that you need a NetApp NOW account to download the SDK.

After you download and extract the SDK, copy the following files to your Puppet Master:
`../lib/ruby/NetApp > [module dir]/netapp/lib/puppet/util/network_device/netapp/`

After the files are copied to a location on your Puppet Master, you need to apply a patch to *NaServer.rb*.  
The patch files are available in the location: `files/NaServer.patch`.  
To apply the patch, change the directory to `netapp` module root directory and run the following:
	
	patch lib/puppet/util/network_device/netapp/NaServer.rb < files/NaServer.patch

This should apply the patch without any exceptions. See below:

	$ patch lib/puppet/util/network_device/netapp/NaServer.rb < files/NaServer.patch
	patching file lib/puppet/util/network_device/netapp/NaServer.rb
	$
	

## Usage

### Device Setup
To configure a NetApp network device, the device *type* should be `netapp`.
You can either configure the device within */etc/puppet/device.conf* or, preferably, create an individual config file for each device within a subfolder.
This is preferred as it allows you to run puppet against individual devices, rather than all devices configured.

To run puppet against a single device, you can use the following command:

    puppet device --deviceconfig /etc/puppet/device/[device].conf

Example configuration `/etc/puppet/device/pfiler01.example.com.conf`:

    [pfiler01.example.com]
      type netapp
      url https://root:secret@pfiler01.example.com

You can also specify a virtual filer that you want to operate on. To specify a virtual filter,
provide the connection information of the physical filer and specify
an optional path that represents the name of the virtual filer. 
Sample configuration `/etc/puppet/device/vfiler01.example.com.conf`:

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

This creates a NetApp volume called `v_volume_name` with a qtree called `q_volume_name`.
The volume will have an initial size of one terabyte (TB) in Aggregate aggr2.
The space reservation mode will be set to volume, and the snapshot space reserve will be set to 20%.
The volume will be able to auto increment, and the NFS export will be persistent.

You can also use any of the types individually, or create new defined types as required.

## Contributors
Thanks to the following people who have helped with this module:
 * Stefan Schulte

## Development

The following section applies to developers of this module only.
Following additional functionalities have been added to the existing NetApp Modules available in the Forge

1> LUN Create and Destroy
2> LUN Offline and Online
3> LUN Clone and Destroy
4> iGroup Create and Destroy
5> LUN Map and UN Map
6> iGroup Add/Remove initiators

## References
Following functionality related readmes are stored in docs folder.

1) lun_create_destroy.md: This readme file describes about the following NetApp functionalities.
   a) Creating LUN
   b) Deleting the LUN.
   
2) lun_online_offline.md: This readme file describes about the following NetApp functionalities.
   a) Bring a LUN online.
   b) Bring a LUN offline.
    
3) lun_clone_destroy.md: This readme file describes the following NetApp functionalities.
   a) Cloning a LUN.
   b) Destroying a clones LUN.
   
4) igroup_create_destroy.md: This readme file describes about the following NetApp functionalities.
   a) Creating an iGroup
   b) Deleting an iGroup
   
5) lun_map_unmap.md: This readme file describes about following the NetApp functionalities.
   a) Mapping a LUN to an iGroup
   b) UN Mapping a LUn from an iGroup.

6) igroup_add_remove_initiator.md: This readme file describes about the following NetApp functionalities.
   a) Adding an initiator to a iGroup.
   b) Removing an initiator from an iGroup.

### Testing

You will need to install the NetApp Manageability SDK Ruby libraries for most of the tests to work.
For the instruction to download the library files, see "NetApp Manageability SDK" section, earlier in this readme.

