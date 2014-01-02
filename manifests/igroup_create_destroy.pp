# == Define: netapp::igroup_create_destroy
#
# Utility class for creation of a NetApp iGroup create and destroy operation.
#

define netapp::igroup_create_destroy (
        $initiatorgrouptype  = '',
        $ensure              = 'present',
        $ostype              =  '',
        ) {

    netapp_igroup_create_destroy { "${name}":
        ensure               => $ensure,
        initiatorgrouptype   => $initiatorgrouptype,
        ostype               => $ostype,
    }
}
