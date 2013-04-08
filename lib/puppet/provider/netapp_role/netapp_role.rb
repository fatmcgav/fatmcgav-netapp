require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_role).provide(:netapp_role, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Role creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  mk_resource_methods
    
  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_role: got to self.instances.")
    
    role_instances = Array.new
    
    # Query Netapp for user role list. 
    result = transport.invoke("useradmin-role-list")
    # Check result status. 
    if(result.results_status == "failed")
      # Check failed, therefore the account doesn't exist. 
      Puppet.debug("Puppet::Provider::Netapp_role: useradmin-role-list failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp_role: useradmin-role-list failed due to #{result.results_reason}. \n."
      return false
    else       
      # Get a list of all roles into array
      role_list = result.child_get("useradmin-roles")
      roles = role_list.children_get()
      
      # Iterate through each 'useradmin-role-info' block. 
      roles.each do |role|
        
        # Pull out relevant info
        rolename = role.child_get_string("name")
        Puppet.debug("Puppet::Provider::Netapp_role.prefetch: Processing role info block for #{rolename}.")          
        
        # Create base hash
        role_info = { :name => rolename,
                      :ensure => :present }
        
        # Get capabilites
        capability_list = String.new
        allowed_capabilities = role.child_get("allowed-capabilities")
        allowed_capabilities_arr = allowed_capabilities.children_get
        allowed_capabilities_arr.each do |allowed_capability|
          capability = allowed_capability.child_get_string("name")
          capability_list << capability + ","
        end
        
        # Add capabilites to hash, removing trailing comma
        role_info[:capabilities] = capability_list.chomp!(",")
        
        # Create the instance and add to role array.
        Puppet.debug("Creating instance for '#{rolename}'. \n")
        role_instances << new(role_info)
          
      end
      
      # Return the final role array. 
      Puppet.debug("Returning role array. ")
      role_instances
    end
  end
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_role: Got to self.prefetch.")
    # Iterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end  
  
  def flush
    Puppet.debug("Puppet::Provider::Netapp_role: Got to flush for resource #{@resource[:rolename]}.")
    
    # Check required resource state
    Puppet.debug("Property_hash ensure = #{@property_hash[:ensure]}")
    case @property_hash[:ensure] 
    when :absent  
      # Query Netapp to remove role.
      result = transport.invoke("useradmin-role-delete", "role-name", @resource[:rolename])
      # Check result returned. 
      if(result.results_status == "failed")
        Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} wasn't deleted due to #{result.results_reason}. \n")
        raise Puppet::Error, "Puppet::Device::Netapp_role: role #{@resource[:rolename]} wasn't deleted due to #{result.results_reason}. \n."
        return false
      else 
        Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} deleted successfully. \n")
        return true
      end
    when :present
      # Query Netapp device to modify role. 
      # Start to construct request
      cmd = NaElement.new("useradmin-role-modify")
        
      # Add useradmin-role container
      role = NaElement.new("useradmin-role")
      
      # Construct useradmin-role-info
      role_info = NaElement.new("useradmin-role-info")
      # Add values
      role_info.child_add_string("name", @resource[:rolename])
      # Add the comment tag if populated. 
      role_info.child_add_string("comment", @resource[:comment]) if @resource[:comment]
      
      # Create useradmin-groups container
      role_capabilities = NaElement.new("allowed-capabilities")
      
      # Split the :capabilities value into array and iterate populating role_capabilites element.
      capabilities = @resource[:capabilities].split(",")
      capabilities.each do |capability|
        capability_info = NaElement.new("useradmin-capability-info")
        capability_info.child_add_string("name", capability)
        role_capabilities.child_add(capability_info)
      end
      
      # Put it all together
      role_info.child_add(role_capabilities)
      role.child_add(role_info)
      cmd.child_add(role)
      
      # Invoke the constructed request
      result = transport.invoke_elem(cmd)
      
      # Check result status
      if(result.results_status == "failed")
        Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} modification failed due to #{result.results_reason}. \n")
        raise Puppet::Error, "Puppet::Device::Netapp_role: role #{@resource[:rolename]} modification failed due to #{result.results_reason}. \n."
        return false
      else
        # Passed above, therefore must of worked. 
        Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} modified successfully. \n")
        return true
      end
    end
  end
  
  def create
    Puppet.debug("Puppet::Provider::Netapp_role: creating Netapp role for #{@resource[:rolename]}. \n")
    
    # Start to construct request
    cmd = NaElement.new("useradmin-role-add")
    
    # Add useradmin-role container
    role = NaElement.new("useradmin-role")
    # Construct useradmin-role-info
    role_info = NaElement.new("useradmin-role-info")
    # Add values
    role_info.child_add_string("name", @resource[:rolename])
    # Add the comment tag if populated. 
    role_info.child_add_string("comment", @resource[:comment]) if @resource[:comment]
    
    # Create allowed-capabilities container
    role_capabilities = NaElement.new("allowed-capabilities")
    
    # Split the :capabilites value into array and iterate populating role_capabilites element.
    capabilities = @resource[:capabilities].split(",")
    capabilities.each do |capability|
      capability_info = NaElement.new("useradmin-capability-info")
      capability_info.child_add_string("name", capability)
      role_capabilities.child_add(capability_info)
    end
    
    # Put it all together
    role_info.child_add(role_capabilities)
    role.child_add(role_info)
    cmd.child_add(role)
    
    # Invoke the constructed request
    result = transport.invoke_elem(cmd)
    
    # Check result status
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp_role: role #{@resource[:rolename]} creation failed due to #{result.results_reason}. \n."
      return false
    else
      # Passed above, therefore must of worked. 
      Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} created successfully. \n")
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_role: destroying Netapp role #{@resource[:rolename]}.")
    @property_hash[:ensure] = :absent
  end
  
  def exists?
    Puppet.debug("Puppet::Provider::Netapp_role: checking existence of Netapp role #{@resource[:rolename]}.")
    Puppet.debug("Value = #{@property_hash[:ensure]}")
    @property_hash[:ensure] == :present
  end
  
end