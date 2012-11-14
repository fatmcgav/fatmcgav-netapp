Puppet::Type.newtype(:netapp_snap_reserve) do 
  @doc = "Manage Netapp Snap Reserve percentage setting."
  
  apply_to_device
  
  ensurable do
    desc "Netapp Snap Reserve resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
  newparam(:name) do
    desc "The volume name."
    isnamevar
  end

  newparam(:reserved) do
    desc "The snap reserve percentage for volume." 
    
    validate do |value|
      raise Puppet::Error, "Puppet::Type::Netapp_snap_reserve: Reserved percentage must be between 0 and 100." unless value.to_i.between?(0,100)
    end    
  end
  
end