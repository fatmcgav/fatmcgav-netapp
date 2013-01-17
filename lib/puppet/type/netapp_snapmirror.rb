Puppet::Type.newtype(:netapp_snapmirror) do 
  @doc = "Manage Netapp Snapmirror creation, modification and deletion."
  
  apply_to_device
  
  ensurable do
    desc "Netapp Snapmirror resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
  newparam(:source_location) do
    desc "The source location."
  end

  newparam(:source_snapshot) do
    desc "The source snapshot name"
  end
  
  newparam(:destination_location) do
    desc "The destination location."
    isnamevar
  end
  
  newparam(:destination_snapshot) do
    desc "The destination snapshot."
  end
  
  newparam(:max_transfer_rate) do 
    desc "The max transfer rate, in KB/s. Defaults to unlimited."
  end
  
end