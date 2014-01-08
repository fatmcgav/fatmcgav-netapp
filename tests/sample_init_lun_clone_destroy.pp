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
  lun_clone { '/vol/testVolume/testLun10':
    ensure                  => 'absent',
    parentlunpath           => '/vol/testVolume/testLun1',
    parentsnap              => 'abc',
    spacereservationenabled => true,
  }
}

