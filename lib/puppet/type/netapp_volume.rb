Puppet::Type.newtype(:netapp_volume) do 
  @doc = "Manage Netapp Volume creation, modification and deletion."
  
  apply_to_device
  
  ensurable do
    desc "Netapp Volume resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
  newparam(:name, :namevar=>true) do
      desc "The volume name."
  
      #newvalues(/^[[:alpha:][:digit:]\.]+$/)
    end

  
end