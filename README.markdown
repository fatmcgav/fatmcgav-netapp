# NetApp network device module

**Note: The device configuration management has been changed as of v0.4.0 of this module. 
You will therefore need to update your device configuration file if upgrading from a version < 0.4.0.**

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

The Netapp network device module has been written and tested against NetApp OnTap 8.0.4 7-mode.
Note: This module may be compatible with other OnTap versions.

## Features
The following items are supported:

 * Creation, modification and deletion of volumes, including auto-increment, snapshot schedules and volume options.
 * Creation, modification and deletion of QTrees.
 * Creation, modification and deletion of NFS Exports, including NFS export security.
 * Creation, modification and deletion of users, groups and roles.
 * Creation, modification and deletion of Quotas. 
 * Creation of snapmirror relationships.
 * Creation of snapmirror schedules.
 * Creation and deletion of LUN.
 * Creation and deletion of LUN clones.
 * Creation and deletion of iGroup.
 * Creation and deletion of initiators.
 * Creation and deletion of LUN mappings.
 * LUN online/offline.
 
 
## Requirements
Since a puppet agent cannot be directly installed on the NetApp filers, it can either be managed from the Puppet Master server,
or through an intermediate proxy system running a puppet agent. The requirements for the proxy system are mentioned below:

 * Puppet 2.7.+
 * NetApp Manageability SDK Ruby libraries

### NetApp Manageability SDK
The NetApp Ruby libraries are contained within the NetApp Manageability SDK, currently at v5.0, which is available to download directly from [NetApp](http://support.netapp.com/NOW/cgi-bin/software?product=NetApp+Manageability+SDK&platform=All+Platforms).
Please note you need a NetApp NOW account to be able to download the SDK.

Once the SDK is downloaded and extracted, the following files need to be copied onto your Puppet Master:
`../lib/ruby/NetApp > [module dir]/netapp/lib/puppet/util/network_device/netapp/`

Once the files have been copied on the Puppet Master, a patch needs to be applied to the *NaServer.rb*.  
The patch file can be found under `files/NaServer.patch`.  
To apply, change into the `netapp` module root directory and run:
	
	patch lib/puppet/util/network_device/netapp/NaServer.rb < files/NaServer.patch

This must apply the patch without any errors, as below:

	$ patch lib/puppet/util/network_device/netapp/NaServer.rb < files/NaServer.patch
	patching file lib/puppet/util/network_device/netapp/NaServer.rb
	$
	

## Usage

### Device Setup
To configure a NetApp network device, the device *type* must be `netapp`.
Either configure the device within */etc/puppet/device.conf* or, preferrably, create an individual config file for each device within a subfolder.
This is preferred as it allows you to run puppet against individual devices, rather than all devices configured...

In order to run Puppet against a single device, use the following command:

    puppet device --deviceconfig /etc/puppet/device/[device].conf

Example configuration `/etc/puppet/device/pfiler01.example.com.conf`:

    [pfiler01.example.com]
      type netapp
      url https://root:secret@pfiler01.example.com

You can also specify a virtual filer to operate on: Simply
provide the connection information for your physical filer and specify
an optional path that represents the name of your virtual filer, for example: configuration `/etc/puppet/device/vfiler01.example.com.conf`:

    [vfiler01.example.com]
      type netapp
      url https://root:secret@pfiler01.example.com/vfiler01

### NetApp operations
As a part of this module, there is a defined type called 'netapp::vqe', which can be used to create a volume, add a qtree and create an NFS export.
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

* lun

This resource type creates a NetApp LUN 

    lun { '/vol/testVol/lun1':
        ensure             => present,
        size_bytes         => 20000000,
        ostype             => vmware,
        space_res_enabled  => true,
    }

name: (Required) This parameter defines the path of the LUN to be created, for example "/vol/TestVol/lun1".

size_bytes: (Required) This parameter defines the size of the LUN in bytes.

space_res_enabled: (Optional) This parameter enables you to create a LUN without any reserve space. By default, the LUN is space reserved. To manage space usage manually, set this parameter value to "false", which will create a LUN without any reserve space.	

* lun_clone

This resource type clones a NetApp LUN

    lun_clone { '/vol/testVol/lun1':
        ensure                      => present,
        parentlunpath               => /vol/TestVol/lun2,
        parentsnap                  => testSnap,
        spacereservationenabled     => true,
    }
    
    
parentlunpath: (Required) This parameter defines the path of original LUN.	     
    
parentsnap: (Required) This parameter defines the LUN path of the backing snapshot.     
    
spacereservationenabled: (Optional) This parameter enables you to create a LUN without any reserve space. By default, the LUN is space-reserved. To manage space usage manually, set this parameter value to "false" which will create a LUN without any reserve space.


* igroup

This resource type creates a NetApp iGroup

    igroup { 'testiGroup':
        ensure               => present,
        initiatorgrouptype   => fcp,
        ostype               => default,
    }
    
name: (Required) This parameter defines the name of the iGroup to be created.
    
initiatorgrouptype: (Required) This parameter defines the type of the initiator group. The possible values are: "fcp", "iscsi", and "mixed". The "mixed" values is available only in Data ONTAP Cluster-Mode 8.1 or later.	     

ostype: (Optional) This parameter defines the OS type of the initiators within the group. If not values is not specified, the default value is "default".  
    

* igroup_initiator

This resource type adds an initiator to a NetApp iGroup

    igroup_initiator { 'testigroup':
           ensure               => present,
           initiator            => 21:00:00:e0:8b:02:e3:45,
           force                => true,
    }


name: (Required) This parameter defines the name of the iGroup being used.

initiator:(Required) This parameter defines the WWPN or Alias of the initiator.	     

force:(Optional) This parameter enables you to forcibly add the initiator. If the 'force' parameter is set to "true", it forcibly adds the initiator by disabling mapping and type conflict checks with the high-availability partner. If not, all the conflict checks are performed.


* lun_map

This resource type will Map a LUN to an iGroup

    lun_map { '/vol/testVolume/lun1':
        ensure            => present,
        initiatorgroup    => testiGroup,
        force      	      => true,
    }

name: (Required) This parameter defines the path of the LUN to be mapped or unmapped.

initiatorgroup: (Required) This parameter defines the initiator group to map the specified LUN.	     
    
force: (Optional) This parameter enables you to forcibly map the LUN, disabling mapping conflict checks with the high-availability partner. If the value is not specified for this parameter, then all conflict checks are performed. In Data ONTAP Cluster-Mode, this field is accepted for backwards compatibility and it is ignored.


* lun_state

This type changes the state of the LUN

    lun_state { '/vol/testVolume/lun1':
        ensure        => present,
        force         => true,
    }
    

name: (Required) This parameter defines the path of the LUN.

force - (Optional) This parameter forcibly brings the LUN online or offline by disabling mapping conflict checks with the high-availability partner. If this parameter is not specified, then all conflict checks are performed.


## Contributors
Thanks to the following people who have helped with this module:
 * Stefan Schulte
 * Gerald Lechner

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


