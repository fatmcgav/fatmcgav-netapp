# == Define: netapp::lun_online_offline
#
# Utility class for creation of a NetApp Lun online/offline operations.
#

define netapp::lun_online_offline (
        $ensure        = 'present',
        $force         = false,
        ) {

    netapp_lun_online_offline { "${name}":
        ensure        => $ensure,
        force         => $force,
    }
}
