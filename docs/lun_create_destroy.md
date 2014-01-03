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

     This method creates the LUN as per the parameters specified in the definition. 

   
  2. Destroy

     This method removes the LUN from the storage device.  


# -------------------------------------------------------------------------
# Summary of Parameters
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the path of the LUN to be created.

    ensure: (Required) This parameter is required to call the 'create' or 'destroy' method.
                       The possible values are: "present" and "absent"
                       If the ensure parameter is set to "present", the module calls the 'create' method.
                       If the ensure parameter is set to "absent", the modules calls the 'destroy' method.
    
    size_bytes:(Required) This parameter defines the size for the LUN in bytes.	     
    
    ostype:(Required) This parameter defines the OS type for the LUN.     
    
    space_res_enabled:(Optional) This parameter enables you to create a LUN without any reserve space. By default, the LUN is space reserved. To manage
                       space usage manually, set this parameter value to "false", which will create a LUN without any reserve space.	    
    

# -------------------------------------------------------------------------
# Parameter Signature 
# -------------------------------------------------------------------------

#Provide transport and LUN properties

define netapp::lun_create_destroy (
        $size_bytes    	     = '2000',
        $ensure        	     = 'present',
        $ostype      		 = '',
        $space_res_enabled   = false, 
        ) {

    netapp_lun_create_destroy { "${name}":
        ensure        	    => $ensure,
        size_bytes          => $size_bytes,
        ostype      	    => $ostype,
        space_res_enabled   => $space_res_enabled,
    }
}

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following files contain the details of the sample init.pp and the supported files:

    - sample_init_lun_create_destroy.pp
    - lun_create_destroy.pp
   
   You can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
