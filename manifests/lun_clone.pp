# == Define: netapp::lun_clone
#
# Utility class for creation of a NetApp Lun clone and destroy operation.
#

define netapp::lun_clone (
        $parentlunpath                           = '',
        $parentsnap                              = '',
        $ensure                                  = 'present',
        $spacereservationenabled                 =  true,
        ) {

    netapp_lun_clone { "${name}":
        ensure                      => $ensure,
        parentlunpath               => $parentlunpath,
        parentsnap                  => $parentsnap,
        spacereservationenabled     => $spacereservationenabled,
    }
}

