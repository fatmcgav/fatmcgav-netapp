require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_user).provide(:cmode, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp user creation, modification and deletion."

  confine :feature => :posix
  defaultfor :feature => :posix

  # Restrict to cMode
  confine :true => begin
    a = Puppet::Node::Facts.indirection
    a.terminus_class = :network_device
    a.find(Puppet::Indirector::Request.new(:facts, :find, "clustered", nil))
  rescue
    :false
  end

  netapp_commands :securitylist => {:api => 'security-login-get-iter', :iter => true, :result_element => 'attributes-list'}
  netapp_commands :udel         => 'useradmin-user-delete'
  netapp_commands :uadd         => 'useradmin-user-add'
  netapp_commands :umodify      => 'useradmin-user-modify'

  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_user::cMode: got to self.instances.")

    # Query Netapp for user list.
    result = securitylist
    
    # Empty accounts array
    account_instances = []

    # Iterate through each 'security-login-account-info' block.
    result.each do |account|

      # Pull out relevant info
      username = account.child_get_string("user-name")
      Puppet.debug("Puppet::Provider::Netapp_user::cMode.prefetch: Processing user info block for #{username}.")

      # Create base hash
      account_info = { :username => username,
                       :ensure   => :present }

      # Add comment if present
      account_info[:comment] = account.child_get_string("comment") unless account.child_get_string("comment").nil?

      # Account locked?
      account_info[:status] = account.child_get_string("is-locked") unless account.child_get_string("is-locked").nil?
        
      # Role
      account_info[:role] = account.child_get_string("role-name") unless account.child_get_string("role-name").nil?
      
      # Application
      account_info[:application] = account.child_get_string("application") unless account.child_get_string("application").nil?
        
      # Authentication method
      account_info[:authmethod] = account.child_get_string("authentication-method") unless account.child_get_string("authentication-method").nil?
          
      # Create the instance and add to users array.
      Puppet.debug("Creating instance for '#{username}'.")
      account_instances << new(account_info)
    end

    # Return the final user array.
    Puppet.debug("Returning user array. ")
    account_instances

  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_user::cMode: Got to self.prefetch.")
    # Iterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.username = #{resources[prov.username]}. ")
      if resource = resources[prov.username]
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
      Puppet.debug("Puppet::Provider::Netapp_user: destroying Netapp user #{@resource[:username]}.")

      # Query Netapp to remove user.
      result = udel('user-name', @resource[:username])
      Puppet.debug("Puppet::Provider::Netapp_user: user #{@resource[:username]} deleted successfully. \n")
      return true

    when :present
      Puppet.debug("Puppet::Provider::Netapp_user: modifying Netapp user account for #{@resource[:username]}.")

      # Construct useradmin-user-info
      user_info = NaElement.new("useradmin-user-info")
      # Add values
      user_info.child_add_string("name", @resource[:username])
      user_info.child_add_string("status", @resource[:status].to_s)

      # Add the full-name tag if populated.
      user_info.child_add_string("full-name", @resource[:fullname]) if @resource[:fullname]

      # Add the comment tag if populated.
      user_info.child_add_string("comment", @resource[:comment]) if @resource[:comment]

      # Add the password-minimum-age tag if populated.
      user_info.child_add_string("password-minimum-age", @resource[:passminage].to_s) if @resource[:passminage]

      # Add the password-maximum-age tag if populated.
      user_info.child_add_string("password-maximum-age", @resource[:passmaxage].to_s) if @resource[:passmaxage]

      # Create useradmin-groups container
      user_groups = NaElement.new("useradmin-groups")

      # Split the :groups value into array and iterate populating user_groups element.
      groups = @resource[:groups].split(",")
      groups.each do |group|
        group_info = NaElement.new("useradmin-group-info")
        group_info.child_add_string("name", group)
        user_groups.child_add(group_info)
      end

      # Put it all together
      user_info.child_add(user_groups)

      # Modify the user
      result = umodify('useradmin-user', user_info)

      # Passed above, therefore must of worked.
      Puppet.debug("Puppet::Provider::Netapp_user: user #{@resource[:username]} modified successfully. \n")
      return true

    end
  end

  def create
    Puppet.debug("Puppet::Provider::Netapp_user: creating Netapp user account for #{@resource[:username]}. \n")

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

    # Split the :groups value into array and iterate populating user_groups element.
    groups = @resource[:groups].split(",")
    groups.each do |group|
      group_info = NaElement.new("useradmin-group-info")
      group_info.child_add_string("name", group)
      user_groups.child_add(group_info)
    end

    # Put it all together
    user_info.child_add(user_groups)

    # Add the user
    result = uadd('useradmin-user', user_info, 'password', @resource[:password])

    # Passed above, therefore must of worked.
    Puppet.debug("Puppet::Provider::Netapp_user: user #{@resource[:username]} created successfully. \n")
    @property_hash.clear
    return true
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_user: destroying Netapp user #{@resource[:username]}.")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_user: checking existence of Netapp user #{@resource[:username]}.")
    Puppet.debug("Value = #{@property_hash[:ensure]}")
    @property_hash[:ensure] == :present
  end

end