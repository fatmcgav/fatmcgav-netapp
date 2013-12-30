# Class: netapp
#
# This module manages netapp
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]

class netapp {
   lun_online_offline { '/vol/testVolumeFCoE/testLun':
      ensure         => 'present',
      force          => true
    }
}

