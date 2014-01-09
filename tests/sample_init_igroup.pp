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
  igroup { 'abcd':
    ensure             => 'present',
    initiatorgrouptype => 'fcp',
    ostype             => 'linux',
    force              =>  true,
  }
}

