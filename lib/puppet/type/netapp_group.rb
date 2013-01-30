Puppet::Type.newtype(:netapp_group) do 
  @doc = "Manage Netapp Group creation, modification and deletion."
  
  apply_to_device
  
  ensurable do
    desc "Netapp Group resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
  newparam(:groupname) do
    desc "The group username."
    isnamevar
    validate do |value|
      unless value =~ /^[\w-]+$/
         raise ArgumentError, "%s is not a valid group name." % value
      end
    end
  end

  newparam(:comment) do
    desc "Group comment"
    validate do |value|
      unless value =~ /^[\w\s\-\.]+$/
         raise ArgumentError, "%s is not a valid comment." % value
      end
    end
  end
  
  newparam(:roles) do
    desc "List of roles for this group. Comma seperate multiple values. "
  end
  
end
