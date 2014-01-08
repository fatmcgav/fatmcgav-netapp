# == Define: netapp::lun_map
#
# Utility class for creation of a NetApp Lun map and unmap operation.
#

define netapp::lun_map (
        $initiatorgroup,
        $ensure        	= 'present',
        $force                =  false, 
        ) {

    netapp_lun_map { "${name}":
        ensure            => $ensure,
        initiatorgroup   => $initiatorgroup,
        force      	      => $force,
    }
}
