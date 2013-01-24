Puppet::Type.newtype(:netapp_qtree) do 
  @doc = "Manage Netapp Qtree creation, modification and deletion."
  
  apply_to_device
  
  ensurable do
    desc "Netapp Qtree resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
  newparam(:name) do
    desc "The qtree name."
    isnamevar
    validate do |value|
      unless value =~ /^\w+$/
         raise ArgumentError, "%s is not a valid qtree name." % value
      end
    end
  end

  newparam(:volume) do
    desc "The volume to create qtree against."
    validate do |value|
      unless value =~ /^\w+$/
         raise ArgumentError, "%s is not a valid volume name." % value
      end
    end   
  end
  
end