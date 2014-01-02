# == Define: netapp::lun_clone_unclone
#
# Utility class for creation of a NetApp Lun clone and destroy operation.
#

define netapp::lun_clone_destroy (
        $parentlunpath                           = '',
        $parentsnap                              = '',
        $ensure                                  = 'present',
        $spacereservationenabled                 =  true,
        ) {

    netapp_lun_clone_destroy { "${name}":
        ensure                      => $ensure,
        parentlunpath               => $parentlunpath,
        parentsnap                  => $parentsnap,
        spacereservationenabled     => $spacereservationenabled,
    }
}

