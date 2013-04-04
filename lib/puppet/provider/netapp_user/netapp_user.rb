require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_user).provide(:netapp_user, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp user creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  mk_resource_methods
  
  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_user: got to self.instances.")
    
    user_instances = Array.new
    
    # Query Netapp for export-list against path. 
    result = transport.invoke("useradmin-user-list", "verbose", "true")
    # Check result status. 
    if(result.results_status == "failed")
      # Check failed, therefore the account doesn't exist. 
      Puppet.debug("Puppet::Provider::Netapp_user: useradmin-user-list failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp Qtree-list failed due to #{result.results_reason}. \n."
      return false
    else 
      # Result returned
      # TODO: Need to work out a way of comparing is user config to should user config.  
      
      # Get a list of all users into array
      user_list = result.child_get("useradmin-users")
      users = user_list.children_get()
      
      # Itterate through each 'useradmin-user-info' block. 
      users.each do |user|
        
        # Pull out relevant info
        username = user.child_get_string("name")
        Puppet.debug("Puppet::Provider::Netapp_user.prefetch: Processing user info block for #{username}.")          
        
        # Create base hash
        user_info = { :name => username,
                      :ensure => :present }
        
        # Add fullname if required
        user_info[:fullname] = user.child_get_string("full-name") unless user.child_get_string("full-name").nil?
        
        # Password min and max ages
        user_info[:passminage] = user.child_get_int("password-minimum-age") unless user.child_get_int("password-minimum-age").nil?
        user_info[:passmaxage] = user.child_get_int("password-maximum-age") unless user.child_get_int("password-maximum-age").nil?
          
        # Get user status
        user_info[:status] = user.child_get_string("status") unless user.child_get_string("status").nil?
          
        # Get groups
        group_list = String.new
        user_groups = user.child_get("useradmin-groups")
        user_groups_arr = user_groups.children_get
        user_groups_arr.each do |user_group|
          group_name = user_group.child_get_string("name")
          group_list << group_name + ","
        end
        
        # Add groups to hash, removing trailing comma
        user_info[:groups] = group_list.chomp!(",")
        
        # Create the instance and add to exports array.
        Puppet.debug("Creating instance for '#{username}'. \n")
        user_instances << new(user_info)
          
      end
      
      # Return the final user array. 
      Puppet.debug("Returning user array. ")
      user_instances
    end
  end
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_user: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end
  
  def flush
    Puppet.debug("Puppet::Provider::Netapp_user: Got to flush for resource #{@resource[:username]}.")
    
    # Check required resource state
    Puppet.debug("Property_hash ensure = #{@property_hash[:ensure]}")
    case @property_hash[:ensure] 
    when :absent
      Puppet.debug("Puppet::Provider::Netapp_user: Ensure is absent.")
      Puppet.debug("Puppet::Provider::Netapp_user: destroying Netapp user #{@resource[:username]}.")
      # Query Netapp to remove qtree against volume. 
      result = transport.invoke("useradmin-user-delete", "user-name", @resource[:username])
      # Check result returned. 
      if(result.results_status == "failed")
        Puppet.debug("Puppet::Provider::Netapp_user: user #{@resource[:username]} wasn't deleted due to #{destroy_result.results_reason}. \n")
        raise Puppet::Error, "Puppet::Device::Netapp user #{@resource[:username]} deletion failed due to #{destroy_result.results_reason} \n."
        return false
      else 
        Puppet.debug("Puppet::Provider::Netapp_user: qtree #{@resource[:username]} destroyed successfully. \n")
        return true
      end
      
    when :present
	Puppet.debug("Puppet::Provider::Netapp_user: Ensure is present.")
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
    user_info.child_add_string("full-name", @resource[:fullname]) if @resource[:fullname]
    
    # Add the comment tag if populated. 
    user_info.child_add_string("comment", @resource[:comment]) if @resource[:comment]
    
    # Add the password-minimum-age tag if populated. 
    user_info.child_add_string("password-minimum-age", @resource[:passminage]) if @resource[:passminage]
    
    # Add the password-maximum-age tag if populated. 
    user_info.child_add_string("password-maximum-age", @resource[:passmaxage]) if @resource[:passmaxage]
    
    # Create useradmin-groups container
    user_groups = NaElement.new("useradmin-groups")
    
    # Split the :groups value into array and itterate populating user_groups element.
    groups = @resource[:groups].split(",")
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
  end
  
  def create
    Puppet.debug("Puppet::Provider::Netapp_user: creating Netapp user account for #{@resource[:username]}. \n")
    @property_hash[:ensure] = :present 
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_user: destroying Netapp user #{@resource[:username]}.")
    @property_hash[:ensure] = :absent
  end
  
  def exists?
    Puppet.debug("Puppet::Provider::Netapp_user: checking existance of Netapp user #{@resource[:username]}.")
    Puppet.debug("Value = #{@property_hash[:ensure]}")
    @property_hash[:ensure] == :present
  end
end

