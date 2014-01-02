# == Define: netapp::lun_create_destroy
#
# Utility class for creation of a NetApp Lun create and destroy operation.
#

define netapp::lun_create_destroy (
        $size_bytes    	     = '',
        $ensure        	     = 'present',
        $ostype      		     = '',
        $space_res_enabled         = true, 
        ) {

    netapp_lun_create_destroy { "${name}":
        ensure        	=> $ensure,
        size_bytes      	=> $size_bytes,
        ostype      	=> $ostype,
        space_res_enabled   => $space_res_enabled,
    }
}
