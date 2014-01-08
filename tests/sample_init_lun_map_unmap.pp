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
  lun_map_unmap { '/vol/testVolumeFCoE/testLun':
    ensure         => 'present',
    initiatorgroup => 'abcd',
    force          => true
  }
}

