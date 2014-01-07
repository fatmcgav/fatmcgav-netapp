# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

  The NetApp storage module uses the NetApp Manageability SDK Ruby libraries to interact with the NetApp storage devices.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Create
	- Destroy

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Create

     This method ensures to bring a LUN online. 

   
  2. Destroy

     The destroy method brings a LUN offline.  


# -------------------------------------------------------------------------
# Summary of Parameters
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the path of the LUN.

    ensure: (Required) This parameter is required to call the 'create' or 'destroy' method.
                       The possible values are: "present" and "absent"
                       If the 'ensure' parameter is set to "present", the module calls the 'create' method.
                       If the 'ensure' parameter is set to "absent", the modules calls the 'destroy' method.
    
    force:(Optional) This parameter forcibly brings the LUN online or offline by disabling mapping conflict checks with the high-availability partner. 
                     If this parameter is not specified, then all conflict checks are performed.
                     

# -------------------------------------------------------------------------
# Parameter Signature 
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
   The following files contain the details of the sample init.pp and the supported files:

    - sample_init_lun_offline_online.pp
    - lun_online_offline.pp
   
   You can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
