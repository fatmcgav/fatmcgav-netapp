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

     This method creates the iGroup as per the parameters specified in the definition. 

   
  2. Destroy

     The method removes the iGroup from the storage device.  


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the name of the iGroup to be created.

    ensure: (Required) This parameter is required to call the 'create' or 'destroy' method.
            The Possible values are: "present" and "absent"
            If the 'ensure' parameter is set to "present", the module calls the 'create' method.
            If the 'ensure' parameter is set to "absent", the modules calls the 'destroy' method.
    
    initiatorgrouptype:(Required) This parameter defines the type of the initiator group. The possible values are: "fcp", "iscsi", and "mixed".
                       The "mixed" values is available only in Data ONTAP Cluster-Mode 8.1 or later.	     

    ostype:(Optional) This parameter defines the OS type of the initiators within the group. If not values is not specified, the default value is "default".
                     

# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and igroup properties

define netapp::igroup_create_destroy (
        $initiatorgrouptype,
        $ensure              = 'present',
        $ostype              =  '',
        ) {

    netapp_igroup_create_destroy { "${name}":
        ensure               => $ensure,
        initiatorgrouptype   => $initiatorgrouptype,
        ostype               => $ostype,
    }
}

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following files contains the details of the sample init.pp and the supported files:

    - sample_init_lun_create_destroy.pp
    - igroup_create_destroy.pp
   
   You can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
