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
  lun { '/vol/testVolumeFCoE/testLun8':
    ensure     => 'present',
    size_bytes => '20000000',
    ostype     => 'linux',
  }
}

