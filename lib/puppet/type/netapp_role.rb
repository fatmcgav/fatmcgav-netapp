Puppet::Type.newtype(:netapp_role) do 
  @doc = "Manage Netapp Role creation, modification and deletion."
  
  apply_to_device
  
  ensurable do
    desc "Netapp Role resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
  newparam(:rolename) do
    desc "The role name."
    isnamevar
    validate do |value|
      unless value =~ /^[\w-]+$/
         raise ArgumentError, "%s is not a valid role name." % value
      end
    end
  end

  newparam(:comment) do
    desc "Role comment"
    validate do |value|
      unless value =~ /^[\w\s\-\.]+$/
         raise ArgumentError, "%s is not a valid comment." % value
      end
    end
  end
  
  newparam(:capabilities) do
    desc "List of capabilities for this role. Comma seperate multiple values. "
  end
  
end
