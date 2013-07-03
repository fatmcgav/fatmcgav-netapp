# NetApp network device module
Warning: This project is work in progress, therefore some functions may not work as expected.

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

Once the files have been copied into place on your Puppet Master, a minor edit is required in *NaServer.rb*:
Replace the line: `require 'NaElement'` with `require File.dirname(__FILE__) + "/NaElement"`.

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

If you attempt to run *puppet device* without this conf file, you will likely see the following error:

    puppet device --deviceconfig test-nactl01.conf -v
    ...
    Error: Can't load netapp for test-nactl01: No such file or directory - /var/lib/puppet/devices/test-nactl01/netapp.yml

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

## TODO
The following items are yet to be implemented:

 * Quota support
 * Data Fabric Manager support
 * Support adding/deleting/modifying cifs shares
 * LDAP and/or AD configuration
 * ???

## Development

The following section applies to developers of this module only.

### Testing

You will need to install the NetApp Manageability SDK Ruby libraries for most of the tests to work.
How to obtain these files is detailed in the NetApp Manageability SDK section above.
