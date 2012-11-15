Puppet::Type.newtype(:netapp_export) do 
  @doc = "Manage Netapp NFS Export creation, modification and deletion."
  
  apply_to_device
  
  ensurable do
    desc "Netapp NFS Export resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
  newparam(:name, :namevar => true) do
    desc "The export name."
  end

  newparam(:persistent) do
    desc "Persistent export?"
    newvalues(:true, :false)
    defaultto(:true)
  end
  
  newparam(:path) do
    desc "The filer path to export."
    defaultto { @resource[:name] }
  end
  
end