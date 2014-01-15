#
# == Define: netapp::createlun
#
# Utility for creating LUN in netapp storage filer.
#
# === Parameters:
#
# === Actions:
#
# === Requires:
#
# === Sample Usage:
#
# netapp::createlun { '/vol/testVolume/testlun32':
#       iGroupName => 'TestGroup1',
#       size => '20000000' ,
#        ostype => 'vmware' ,
#        initiatorgrouptype => 'fcp',
#        initiator => '20:01:74:86:7a:d7:cb:59',
#}
#
#
define netapp::createlun (
        $iGroupName ,
        $size ,
        $ostype ,
        $space_res_enabled = true ,
        $initiatorgrouptype ,
        $initiator,
        $force = true,
        $ensure = 'present',
        ) {

    netapp_lun { "$name":
        ensure            => $ensure,
        size_bytes        => $size,
        ostype            => $ostype,
        space_res_enabled => $space_res_enabled,
    }

    netapp_igroup { "$iGroupName":
        ensure             => $ensure,
        initiatorgrouptype => $initiatorgrouptype,
        ostype             => $ostype,
        force              => $force,
    }

    netapp_igroup_initiator { "$iGroupName":
        ensure    => $ensure,
        initiator => $initiator,
        force     => $force,
    }

    netapp_lun_map { "$name":
        ensure         => $ensure,
        initiatorgroup => $iGroupName,
        force          => $force,
    }

    Netapp_lun["$name"]
        -> Netapp_igroup["$iGroupName"]
        -> Netapp_igroup_initiator["$iGroupName"]
        -> Netapp_lun_map["$name"]
}

