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

     The create method creates the iGroup as per the parameters specified in the definition. 

   
  2. Destroy

     The destroy method removes the iGroup from the storage device.  


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the Path of the LUN to be created.

    ensure: (Required) This parameter is required to call the create or destroy method.
    Possible values: present/absent
    If the value of the ensure parameter is set to present, the module calls the create method.
    If the value of the ensure parameter is set to absent, the modules calls the destroy method.
    
    initiatorgrouptype:(Required) Type of the initiator group. Possible values: "fcp", "iscsi", "mixed".
                       "mixed" is available in Data ONTAP Cluster-Mode 8.1 or later only.	     

    ostype:(Optional) OS type of the initiators within the group. The default value if not specified is "default".
                     

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
   The following files capture the details of the sample init.pp and the supported files:

    - sample_init_lun_create_destroy.pp
    - igroup_create_destroy.pp
   
   A user can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
