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

     This method clones the LUN as per the parameters specified in the definition. 

   
  2. Destroy

     This method removes the cloned LUN from the storage device.  


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the path of the LUN to be created after cloning.

    ensure: (Required) This parameter is required to call the 'create' or 'destroy' method.
                       The possible values are: "present" and "absent"
                       If the ensure parameter is set to "present", the module calls the 'create' method.
                       If the ensure parameter is set to "absent", the modules calls the 'destroy' method.
    
    parentlunpath:(Required) This parameter defines the path of original LUN.	     
    
    parentsnap:(Required) This parameter defines the LUN path of the backing snapshot.     
    
    spacereservationenabled:(Optional) This parameter enables you to create a LUN without any reserve space. By default, the LUN is space-reserved. To manage
                            space usage manually, set this parameter value to "false" which will create a LUN without any reserve space.		    
    

# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and LUN properties

define netapp::lun_clone_destroy (
        $parentlunpath,
        $parentsnap,
        $ensure                       = 'present',
        $spacereservationenabled      =  false,
        ) {

    netapp_lun_clone_destroy { "${name}":
        ensure                      => $ensure,
        parentlunpath               => $parentlunpath,
        parentsnap                  => $parentsnap,
        spacereservationenabled     => $spacereservationenabled,
    }
}

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following files contains the details of the sample init.pp and the supported files:

    - sample_init_lun_clone_destroy.pp
    - lun_clone_destroy.pp
   
   You can can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
