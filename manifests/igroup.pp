# == Define: netapp::igroup
#
# Utility class for creation of a NetApp iGroup create and destroy operation.
#

define netapp::igroup (
  $initiatorgrouptype = '', 
  $ensure = 'present', 
  $ostype = '',) {
  netapp_igroup { "${name}":
    ensure             => $ensure,
    initiatorgrouptype => $initiatorgrouptype,
    ostype             => $ostype,
  }
}
