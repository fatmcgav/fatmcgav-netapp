# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The NetApp storage module uses the NetApp Manageability SDK Ruby libraries to interact with the NetApp storage device.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Create
	- Destroy

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Create

     The create method Maps the LUN with a give iGroup. 

   
  2. Destroy

     The destroy method Un Maps the LUn from a given iGroup.  


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the Path of the LUN to be mapped/unmapped.

    ensure: (Required) This parameter is required to call the create or destroy method.
                       Possible values: present/absent
                       If the value of the ensure parameter is set to present, the module calls the create method.
                       If the value of the ensure parameter is set to absent, the modules calls the destroy method.
    
    initiatorgroup:(Required) This parameter defines the initiator group to map to the given LUN.	     
    
    lunid:(optional) If the lun-id is not specified, the smallest number that can be used for the various initiators
                     in the group is automatically picked. Value can range between [0..4095]
    
    force:(Optional) Forcibly map the lun, disabling mapping conflict checks with the high-availability partner.
                     If not specified all conflict checks are performed. In Data ONTAP Cluster-Mode, this field is
                     accepted for backwards compatibilty and is ignored.

# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and LUN properties

define netapp::lun_map_unmap (
        $initiatorgroup,
        $lunid                = '',
        $ensure        	      = 'present',
        $force                =  true, 
        ) {

    netapp_lun_map_unmap { "${name}":
        ensure            => $ensure,
        initiatorgroup    => $initiatorgroup,
        lunid             => $lunid,
        force      	      => $force,
    }
}

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following files capture the details of the sample init.pp and the supported files:

    - sample_init_lun_map_unmap.pp
    - lun_map_unmap.pp
   
   A user can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
