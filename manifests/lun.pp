# == Define: netapp::lun
#
# Utility class for creation of a NetApp Lun create and destroy operation.
#

define netapp::lun (
  $size_bytes = '', 
  $ensure = 'present', 
  $ostype = '', 
  $space_res_enabled = true,) {
  netapp_lun { "${name}":
    ensure            => $ensure,
    size_bytes        => $size_bytes,
    ostype            => $ostype,
    space_res_enabled => $space_res_enabled,
  }
}
