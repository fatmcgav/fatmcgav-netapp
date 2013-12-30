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

     The create method ensures that a given LUN is bought online. 

   
  2. Destroy

     The destroy method brings the LUN offline.  


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the path of the LUN.

    ensure: (Required) This parameter is required to call the create or destroy method.
                       Possible values: present/absent
                       If the value of the ensure parameter is set to present, the module calls the create method.
                       If the value of the ensure parameter is set to absent, the modules calls the destroy method.
    
    force:(Optional) This parameter forcibly online/offline the lun, disabling mapping onflict checks with the high-availability partner. 
                     If not specified all conflict checks are performed
                     

# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and LUN properties

define netapp::lun_online_offline (
        $ensure        = 'present',
        $force         = false,
        ) {

    netapp_lun_online_offline { "${name}":
        ensure        => $ensure,
        force         => $force,
    }
}


# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following files capture the details of the sample init.pp and the supported files:

    - sample_init_lun_offline_online.pp
    - lun_online_offline.pp
   
   A user can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
