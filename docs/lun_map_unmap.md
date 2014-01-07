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

     This method maps the LUN with the specified iGroup. 

   
  2. Destroy

     The destroy method unmaps the LUN from the specified iGroup.  


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the path of the LUN to be mapped or unmapped.

    ensure: (Required) This parameter is required to call the 'create' or 'destroy' method.
                       The possible values are: "present" and "absent"
                       If the ensure parameter is set to "present", the module calls the 'create' method.
                       If the ensure parameter is set to "absent", the modules calls the 'destroy' method.
    
    initiatorgroup:(Required) This parameter defines the initiator group to map the specified LUN.	     
    
    lunid:(optional) If the value for 'lunid' is not specified, the smallest number that can be used for the various initiators
                     in the group is automatically picked. The 'lunid' value must be between: 0 and 4095
    
    force:(Optional) This parameter enables you to forcibly map the LUN, disabling mapping conflict checks with the high-availability partner.
                     If the value is not specified for this parameter, then all conflict checks are performed. In Data ONTAP Cluster-Mode, this field is
                     accepted for backwards compatibility and it is ignored.

# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and LUN properties

define netapp::lun_map_unmap (
        $initiatorgroup,
        $ensure        	      = 'present',
        $force                =  true, 
        ) {

    netapp_lun_map_unmap { "${name}":
        ensure            => $ensure,
        initiatorgroup    => $initiatorgroup,
        force      	      => $force,
    }
}

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following files contains the details of the sample init.pp and the supported files:

    - sample_init_lun_map_unmap.pp
    - lun_map_unmap.pp
   
   You can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
