# == Define: netapp::lun_map_unmap
#
# Utility class for creation of a NetApp Lun create and destroy operation.
#

define netapp::lun_map_unmap (
        $initiatorgroup,
        $ensure        	= 'present',
        $force                =  false, 
        ) {

    netapp_lun_map_unmap { "${name}":
        ensure            => $ensure,
        initiatorgroup   => $initiatorgroup,
        force      	      => $force,
    }
}
