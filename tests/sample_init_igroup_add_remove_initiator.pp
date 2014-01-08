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
  igroup_initiator { 'abcd':
    ensure    => 'present',
    initiator => 'testuser',
    force     => true,
  }
}

