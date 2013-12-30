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

     The create method clones the LUN as per the parameters specified in the definition. 

   
  2. Destroy

     The destroy method removes the cloned LUN from the storage device.  


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the Path of the LUN to be created after cloning.

    ensure: (Required) This parameter is required to call the create or destroy method.
                       Possible values: present/absent
                       If the value of the ensure parameter is set to present, the module calls the create method.
                       If the value of the ensure parameter is set to absent, the modules calls the destroy method.
    
    parentlunpath:(Required) This parameter defines the path of original LUN.	     
    
    parentsnap:(Required) This parameter defines the LUN path of the backing snapshot.     
    
    spacereservationenabled:(Optional) By default, the lun is space-reserved. If it is desired to manage
                      space usage manually instead,this can be set to "false" which will create a LUN without
                      any space being reserved.		    
    

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
   The following files capture the details of the sample init.pp and the supported files:

    - sample_init_lun_clone_destroy.pp
    - lun_clone_destroy.pp
   
   A user can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
