require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_user).provide(:netapp_user, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp user creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def create
    Puppet.debug("Puppet::Provider::Netapp_user: creating Netapp user account for #{@resource[:username]}. \n")
    
    # Start to construct request
    cmd = NaElement.new("useradmin-user-add")
    cmd.child_add_string("password", @resource[:password])
      
    # Add useradmin-user container
    user = NaElement.new("useradmin-user")
    
    # Construct useradmin-user-info
    user_info = NaElement.new("useradmin-user-info")
    # Add values
    user_info.child_add_string("name", @resource[:username])
    user_info.child_add_string("status", @resource[:status])
    # Add the full-name tag if populated. 
    if @resource[:fullname]
      user_info.child_add_string("full-name", @resource[:fullname])
    end
    # Add the comment tag if populated. 
    if @resource[:comment]
      user_info.child_add_string("comment", @resource[:comment])
    end
    # Add the password-minimum-age tag if populated. 
    if @resource[:passminage]
      user_info.child_add_string("password-minimum-age", @resource[:passminage])
    end
    # Add the password-maximum-age tag if populated. 
    if @resource[:passmaxage]
      user_info.child_add_string("password-maximum-age", @resource[:passmaxage])
    end
    
    # Create useradmin-groups container
    user_groups = NaElement.new("useradmin-groups")
    
    # Split the :groups value into array and itterate populating user_groups element.
    groups = @resource[:name].split(",")
    groups.each do |group|
      group_info = NaElement.new("useradmin-group-info")
      group_info.child_add_string("name", group)
      user_groups.child_add(group_info)
    end
    
    # Put it all togeather
    user_info.child_add(user_groups)
    user.child_add(user_info)
    cmd.child_add(user)
    
    # Invoke the constructed request
    result = transport.invoke_elem(cmd)
    
    # Check result status
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_user: user #{@resource[:username]} creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp user #{@resource[:username]} creation failed due to #{result.results_reason}. \n."
      return false
    else
      # Passed above, therefore must of worked. 
      Puppet.debug("Puppet::Provider::Netapp_user: user #{@resource[:username]} created successfully. \n")
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_user: destroying Netapp user #{@resource[:username]}. \n")
    # Query Netapp to remove export against path. 
    result = transport.invoke("useradmin-user-delete", "user-name", @resource[:username])
    # Check result returned. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_user: user #{@resource[:username]} wasn't deleted due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp user #{@resource[:username]} wasn't deleted due to #{result.results_reason}. \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_user: user #{@resource[:username]} deleted successfully. \n")
      return true
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_user: checking existance of Netapp user account #{@resource[:username]}. \n")
    # Query Netapp for export-list against path. 
    result = transport.invoke("useradmin-user-list", "user-name", @resource[:username])
    # Check result status. 
    if(result.results_status == "failed")
      # Check failed, therefore the account doesn't exist. 
      Puppet.debug("Puppet::Provider::Netapp_user: User account #{@resource[:username]} doesn't exist. \n")
      return false
    else 
      # Result returned
      # TODO: Need to work out a way of comparing is user config to should user config.  
      Puppet.debug("Puppet::Provider::Netapp_user: User account #{@resource[:username]} does exist. \n")
      return true
    end

  end
  
end