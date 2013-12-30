# == Define: netapp::lun_clone_unclone
#
# Utility class for creation of a NetApp Lun clone and destroy operation.
#

define netapp::lun_clone_unclone (
  $parentlunpath,
  $parentsnap,
  $ensure                                  = 'present',
  $spacereservationenabled                 =  false,
) {

  netapp_lun_clone_unclone { "${name}":
    ensure                      => $ensure,
    parentlunpath               => $parentlunpath,
    parentsnap                  => $parentsnap,
    spacereservationenabled     => $spacereservationenabled,
  }
 }

