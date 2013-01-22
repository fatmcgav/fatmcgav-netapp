require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_role).provide(:netapp_role, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Role creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def create
    Puppet.debug("Puppet::Provider::Netapp_role: creating Netapp role for #{@resource[:rolename]}. \n")
    
    # Start to construct request
    cmd = NaElement.new("useradmin-role-add")
    
    # Construct useradmin-role-info
    role_info = NaElement.new("useradmin-role-info")
    # Add values
    role_info.child_add_string("name", @resource[:rolename])
    # Add the comment tag if populated. 
    if @resource[:comment]
      role_info.child_add_string("comment", @resource[:comment])
    end
    
    # Create useradmin-groups container
    role_capabilities = NaElement.new("allowed-capabilities")
    
    # Split the :groups value into array and itterate populating role_groups element.
    capabilities = @resource[:capabilities].split(",")
    capabilities.each do |capability|
      capability_info = NaElement.new("useradmin-capability-info")
      capability_info.child_add_string("name", capability)
      role_capabilities.child_add(capability_info)
    end
    
    # Put it all togeather
    role_info.child_add(role_capabilities)
    cmd.child_add(role_info)
    
    # Invoke the constructed request
    result = transport.invoke_elem(cmd)
    
    # Check result status
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp role #{@resource[:rolename]} creation failed due to #{result.results_reason}. \n."
      return false
    else
      # Passed above, therefore must of worked. 
      Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} created successfully. \n")
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_role: destroying Netapp role #{@resource[:rolename]}. \n")
    # Query Netapp to remove role. 
    result = transport.invoke("useradmin-role-delete", "role-name", @resource[:rolename])
    # Check result returned. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} wasn't deleted due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp role #{@resource[:rolename]} wasn't deleted due to #{result.results_reason}. \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} deleted successfully. \n")
      return true
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_role: checking existance of Netapp role #{@resource[:rolename]}. \n")
    # Query Netapp for role list. 
    result = transport.invoke("useradmin-role-list")
    # Check result status. 
    if(result.results_status == "failed")
      # Check for failure. 
      Puppet.debug("Puppet::Provider::Netapp_role: useradmin-role-list failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp useradmin-role-list failed due to #{result.results_reason}. \n."
      return false
    else 
      # Get a list of roles
      role_list = result.child_get("useradmin-roles")
      roles = role_list.children_get
      # Itterate through each 'useradmin-role-info' block. 
      roles.each do |role|
        # Check if the role name matches the resource name we're validating. 
        if(role.child_get_string("name") == @resource[:rolename])
          # Match found, return true. 
          # TODO: Need to identify a method of verifying the allowed capabilities match. 
          Puppet.debug("Puppet::Provider::Netapp_role: Matching role exists. \n")
          return true
        end
      end
      
      # No match found, therefore role doesn't exist. Return false.  
      Puppet.debug("Puppet::Provider::Netapp_role: Matching role doesn't exist. \n")
      return false
    end

  end
  
end