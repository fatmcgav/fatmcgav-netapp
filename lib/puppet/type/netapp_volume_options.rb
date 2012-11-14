Puppet::Type.newtype(:netapp_volume_options) do 
  @doc = "Manage Netapp Volume Option modification."
  
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
  
  newparam(:name) do
    desc "The volume name to set options against."
    isnamevar
  end
  
  newparam(:options, :array_matching => :all) do
    desc "Hash of options to be applied to this volume."
    
    validate do |value|
      raise Puppet::Error, "Puppet::Type::Netapp_volume_options: options property must be a hash." unless value.is_a? Hash
    end
  end
end