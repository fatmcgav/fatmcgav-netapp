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

     The create method adds the initiator to the iGroup. 

   
  2. Destroy

     The destroy method removes the initiator from the iGroup.  


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the name of the iGroup being used.

    ensure: (Required) This parameter is required to call the create or destroy method.
                       Possible values: present/absent
                       If the value of the ensure parameter is set to present, the module calls the create method.
                       If the value of the ensure parameter is set to absent, the modules calls the destroy method.
    
    initiator:(Required) This parameter defines the WWPN or Alias of Initiator.	     

    force:(Optional) This parameter if set to "true" forcibly add the initiator, disabling mapping
                     and type conflict checks with the high-availability partner. If not specified all 
                     conflict checks are performed.
                     

# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and igroup properties

define netapp::igroup_add_remove_initiator (
  $initiator,
  $ensure              = 'present',
  $force               = false,
) {

  netapp_igroup_add_remove_initiator { "${name}":
    ensure               => $ensure,
    initiator            => $initiator,
    force                => $force,
  }
 }


# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following files capture the details of the sample init.pp and the supported files:

    - sample_init_igroup_add_remove_initiator.pp
    - igroup_add_remove_initiator.pp
   
   A user can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
