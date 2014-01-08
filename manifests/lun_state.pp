# == Define: netapp::lun_state
#
# Utility class for creation of a NetApp Lun online/offline operations.
#

define netapp::lun_state ($ensure = 'present', $force = false,) {
  netapp_lun_state { "${name}":
    ensure => $ensure,
    force  => $force,
  }
}
