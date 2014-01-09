# == Define: netapp::igroup
#
# Utility class for creation of a NetApp iGroup create and destroy operation.
#

define netapp::igroup (
  $initiatorgrouptype = '', 
  $ensure = 'present', 
  $ostype = '',
  $force  = false,) {
  netapp_igroup { "${name}":
    ensure             => $ensure,
    initiatorgrouptype => $initiatorgrouptype,
    ostype             => $ostype,
    force              => $force,
  }
}
