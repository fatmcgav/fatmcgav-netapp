require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_group).provide(:netapp_group, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp group creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def create
    Puppet.debug("Puppet::Provider::Netapp_group: creating Netapp group for #{@resource[:groupname]}. \n")
    
    # Start to construct request
    cmd = NaElement.new("useradmin-group-add")
      
    # Add useradmin-group container
    group = NaElement.new("useradmin-group")
    
    # Construct useradmin-user-info
    group_info = NaElement.new("useradmin-group-info")
    # Add values
    group_info.child_add_string("name", @resource[:groupname])
    # Add the comment tag if populated. 
    if @resource[:comment]
      group_info.child_add_string("comment", @resource[:comment])
    end
    
    # Create useradmin-groups container
    group_roles = NaElement.new("useradmin-roles")
    
    # Split the :groups value into array and itterate populating user_groups element.
    roles = @resource[:roles].split(",")
    roles.each do |role|
      role_info = NaElement.new("useradmin-role-info")
      role_info.child_add_string("name", role)
      group_roles.child_add(role_info)
    end
    
    # Put it all togeather
    group_info.child_add(group_roles)
    group.child_add(group_info)
    cmd.child_add(group)
    
    # Invoke the constructed request
    result = transport.invoke_elem(cmd)
    
    # Check result status
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_group: group #{@resource[:groupname]} creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp group #{@resource[:groupname]} creation failed due to #{result.results_reason}. \n."
      return false
    else
      # Passed above, therefore must of worked. 
      Puppet.debug("Puppet::Provider::Netapp_group: group #{@resource[:groupname]} created successfully. \n")
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_group: destroying Netapp group #{@resource[:groupname]}. \n")
    # Query Netapp to remove export against path. 
    result = transport.invoke("useradmin-group-delete", "group-name", @resource[:groupname])
    # Check result returned. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_group: group #{@resource[:groupname]} wasn't deleted due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp group #{@resource[:groupname]} wasn't deleted due to #{result.results_reason}. \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_group: group #{@resource[:groupname]} deleted successfully. \n")
      return true
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_group: checking existance of Netapp group account #{@resource[:groupname]}.")
    # Query Netapp for export-list against path. 
    result = transport.invoke("useradmin-group-list", "group-name", @resource[:groupname])
    # Check result status. 
    if(result.results_status == "failed")
      # Check failed, therefore the group doesn't exist. 
      Puppet.debug("Puppet::Provider::Netapp_group: Group #{@resource[:groupname]} doesn't exist. \n")
      return false
    else 
      # Result returned 
      Puppet.debug("Puppet::Provider::Netapp_group: Group #{@resource[:groupname]} does exist. \n")
      return true
    end

  end
  
end