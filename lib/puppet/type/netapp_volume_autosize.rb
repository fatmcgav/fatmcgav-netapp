Puppet::Type.newtype(:netapp_volume_autosize) do 
  @doc = "Manage Netapp Volume Autosize settings."
  
  apply_to_device
  
  ensurable do
    desc "Netapp Volume autosize resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    # Alias enabled onto present
    aliasvalue(:enabled, :present)
    
    newvalue(:absent) do 
      provider.destroy
    end
    
    # Alias disabled onto absent
    aliasvalue(:disabled, :absent)
    
  end
  
  newparam(:name, :namevar => true) do
    desc "The volume name."
  end

  newparam(:reserved) do
    desc "The snap reserve percentage for volume." 
    
    validate do |value|
      raise Puppet::Error, "Puppet::Type::Netapp_snap_reserve: Reserved percentage must be between 0 and 100." unless value.to_i.between?(0,100)
    end    
  end
  
end