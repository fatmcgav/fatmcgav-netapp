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
  end

  newparam(:volume) do
    desc "The volume to create qtree against."     
  end
  
end