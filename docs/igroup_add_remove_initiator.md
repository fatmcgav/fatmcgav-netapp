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

     The 'Create' method adds the initiator to the iGroup. 

   
  2. Destroy

     The 'Destroy' method removes the initiator from the iGroup.  


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required) This parameter defines the name of the iGroup being used.

    ensure: (Required) This parameter is required to call the 'Create' or 'Destroy' method.
                       The possible values are: "present" and "absent"
                       If the 'ensure' parameter is set to "present", the module calls the 'Create' method.
                       If the 'ensure' parameter is set to "absent", the modules calls the 'Destroy' method.
    
    initiator:(Required) This parameter defines the WWPN or Alias of the initiator.	     

    force:(Optional) This parameter enables you to forcibly add the initiator.
                     If the 'force' parameter is set to "true", it forcibly adds the initiator by disabling mapping
                     and type conflict checks with the high-availability partner. 
					 If not, all the conflict checks are performed.
                     

# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and iGroup properties

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
   The following files contain the details of the sample init.pp and the supported files:

    - sample_init_igroup_add_remove_initiator.pp
    - igroup_add_remove_initiator.pp
   
   You can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	
