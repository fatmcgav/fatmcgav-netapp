0.4.0 2013-09-30 Gavin Williams <fatmcgav@gmail.com>
Feature release incorporating multiple changes. 
Many thanks to Stefan Schulte for a large amount of the changes. 
Noteworthy changes:
* (#41) Added the netapp_quota type/provider. 
* (#43) Remove the need for a special configuration file - 
  Instead get username and password from connection string.
* Simplify calling of netapp commands by using netapp_commands function. 
* Loads more tests, with some new integration/unit tests. 
* Various types will auto-require any appropriate resources that they should depend on. 
  E.g. Netapp_export will auto-require the appropriate netapp_volume or netapp_qtree. 
  Netapp_user will auto-require the appropriate netapp_group.
* Some improvements to facts being returned.

0.3.0 2013-04-09 Gavin Williams <fatmcgav@gmail.com>
Feature release incorporating 2 enhancements.
* (#18) Improved device facts
  Now gives more meaningful fact data.  
* (#20) Convert to Prefetch/Flush style providers.
  Large performance improvement by converting to a prefetch/flush model for providers.  
Also improved Readme, and correct various typos and incorrect code comments. 

0.2.4 2013-03-28 Gavin Williams <fatmcgav@gmail.com>
* (#27) Updated netapp_volume autoincrement= to convert volume size into MB before calculating autoincrement sizes. 

0.2.3 2013-03-22 Gavin Williams <fatmcgav@gmail.com>
* (#13) Updated Netapp_volume to adjust the auto-increment settings when resizing a volume. 

0.2.2 2013-03-15 Gavin Williams <fatmcgav@gmail.com>
* (#24) Updated Netapp_export provider to fix a destroy bug. 

0.2.1 2013-03-07 Gavin Williams <fatmcgav@gmail.com>
* (#22) Updated Netapp_Export type to not default :path to :name, as causes OnTap API call to fail.

0.2.0 2013-03-06 Gavin Williams <fatmcgav@gmail.com>
* (#19) Fix Netapp_qtree handling of missing volume. 
* (#12) Add support for NetApp NFS export security. 

0.1.2 2013-02-06 Gavin Williams <fatmcgav@gmail.com>
* (#14) Fix Snapschedule bug with which-days and nil versus 0

0.1.1 2013-01-30 Gavin Williams <fatmcgav@gmail.com>
* (#9) Updated netapp_user, netapp_group and netapp_role name input validation to support '-'.
* (#10) Updated netapp_volume type/provider to fix snapschedule property bug.

0.1.0 2013-01-12 Gavin Williams <fatmcgav@gmail.com>
* Initial release.