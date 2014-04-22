require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_role).provide(:netapp_role, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Role creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :rlist   => 'useradmin-role-list'
  netapp_commands :rdel    => 'useradmin-role-delete'
  netapp_commands :radd    => 'useradmin-role-add'
  netapp_commands :rmodify => 'useradmin-role-modify'
  
  mk_resource_methods
    
  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_role: got to self.instances.")
    
    role_instances = []
    
    # Query Netapp for user role list. 
    result = rlist
     
    # Get a list of all roles into array
    role_list = result.child_get("useradmin-roles")
    roles = role_list.children_get()
    
    # Iterate through each 'useradmin-role-info' block. 
    roles.each do |role|
      
      # Pull out relevant info
      rolename = role.child_get_string("name")
      Puppet.debug("Puppet::Provider::Netapp_role.prefetch: Processing role info block for #{rolename}.")
      
      # Create base hash
      role_info = { :rolename => rolename,
                    :ensure   => :present }
      
      # Add comment if present
      role_info[:comment] = role.child_get_string("comment") unless role.child_get_string("comment").nil?
      
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
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_role: Got to self.prefetch.")
    # Iterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.rolename = #{resources[prov.rolename]}. ")
      if resource = resources[prov.rolename]
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
      result = rdel("role-name", @resource[:rolename])
      
      Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} deleted successfully. \n")
      return true
    when :present
      # Query Netapp device to modify role. 
      
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
      
      # Invoke the constructed request
      result = rmodify('useradmin-role', role_info)
      
      # Passed above, therefore must of worked. 
      Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} modified successfully. \n")
      return true
    end
  end
  
  def create
    Puppet.debug("Puppet::Provider::Netapp_role: creating Netapp role for #{@resource[:rolename]}. \n")

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
    
    # Invoke the constructed request
    result = radd('useradmin-role', role_info)
    
    # Passed above, therefore must of worked. 
    Puppet.debug("Puppet::Provider::Netapp_role: role #{@resource[:rolename]} created successfully. \n")
    return true
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