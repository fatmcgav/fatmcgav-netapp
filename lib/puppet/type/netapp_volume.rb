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

  newparam(:initsize) do
    desc "The initial volume size."
     
  end
  
  newparam(:aggr) do
    desc "The aggregate this volume should be created in." 
    
  end
  
  newparam(:spaceresv) do
    desc "The space reservation mode."
    
  end
end