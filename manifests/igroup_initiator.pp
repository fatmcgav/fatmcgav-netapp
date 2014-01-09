# == Define: netapp::igroup_initiator
#
# Utility class for creation of a NetApp iGroup add and remove initiator operation.
#

define netapp::igroup_initiator (
  $initiator, 
  $ensure = 'present', 
  $force = false,) {
  netapp_igroup_initiator { "${name}":
    ensure    => $ensure,
    initiator => $initiator,
    force     => $force,
  }
}
