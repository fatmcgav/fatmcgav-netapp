require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_group).provide(:netapp_group, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp group creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  mk_resource_methods
  
  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_group: got to self.instances.")
    
    group_instances = Array.new
    
    # Query Netapp for export-list against path. 
    result = transport.invoke("useradmin-group-list")
    # Check result status. 
    if(result.results_status == "failed")
      # Check failed, therefore the account doesn't exist. 
      Puppet.debug("Puppet::Provider::Netapp_user: useradmin-group-list failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp useradmin-group-list failed due to #{result.results_reason}. \n."
      return false
    else       
      # Get a list of all groups into array
      group_list = result.child_get("useradmin-groups")
      groups = group_list.children_get()
      
      # Itterate through each 'useradmin-group-info' block. 
      groups.each do |group|
        
        # Pull out relevant info
        groupname = group.child_get_string("name")
        Puppet.debug("Puppet::Provider::Netapp_group.prefetch: Processing group info block for #{groupname}.")          
        
        # Create base hash
        group_info = { :name => groupname,
                      :ensure => :present }
        
        # Get roles
        role_list = String.new
        group_roles = user.child_get("useradmin-roles")
        group_roles_arr = group_roles.children_get
        group_roles_arr.each do |group_role|
          role_name = group_role.child_get_string("name")
          role_list << role_name + ","
        end
        
        # Add groups to hash, removing trailing comma
        group_info[:roles] = role_list.chomp!(",")
        
        # Create the instance and add to group array.
        Puppet.debug("Creating instance for '#{groupname}'. \n")
        group_instances << new(group_info)
          
      end
      
      # Return the final user array. 
      Puppet.debug("Returning group array. ")
      group_instances
    end
  end
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_groups: Got to self.prefetch.")
    # Iterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end
  
  def flush
    Puppet.debug("Puppet::Provider::Netapp_group: Got to flush for resource #{@resource[:groupname]}.")
    
    # Check required resource state
    Puppet.debug("Property_hash ensure = #{@property_hash[:ensure]}")
    case @property_hash[:ensure] 
    when :absent  
      # Query Netapp to remove user group.
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
    when :present
      # Query Netapp device to modify user group. 
      # Start to construct request
      cmd = NaElement.new("useradmin-group-modify")
        
      # Add useradmin-group container
      group = NaElement.new("useradmin-group")
      
      # Construct useradmin-user-info
      group_info = NaElement.new("useradmin-group-info")
      # Add values
      group_info.child_add_string("name", @resource[:groupname])
      # Add the comment tag if populated. 
      group_info.child_add_string("comment", @resource[:comment]) if @resource[:comment]
      
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
  end
  
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
    group_info.child_add_string("comment", @resource[:comment]) if @resource[:comment]
    
    # Create useradmin-groups container
    group_roles = NaElement.new("useradmin-roles")
    
    # Split the :groups value into array and iterate populating user_groups element.
    roles = @resource[:roles].split(",")
    roles.each do |role|
      role_info = NaElement.new("useradmin-role-info")
      role_info.child_add_string("name", role)
      group_roles.child_add(role_info)
    end
    
    # Put it all together
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
      @property_hash.clear
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_group: destroying Netapp group #{@resource[:groupname]}.")
    @property_hash[:ensure] = :absent
  end
  
  def exists?
    Puppet.debug("Puppet::Provider::Netapp_groupr: checking existence of Netapp group #{@resource[:groupname]}.")
    Puppet.debug("Value = #{@property_hash[:ensure]}")
    @property_hash[:ensure] == :present
  end
  
end