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
  
  newproperty(:volume, :namevar => true) do
    desc "The volume name."
  end

  newparam(:initsize) do
    desc "The initial volume size."
    defaultto "1g"
  end
  
  newparam(:aggregate) do
    desc "The aggregate this volume should be created in." 
  end
  
  newparam(:spaceres) do
    desc "The space reservation mode."
  end
  
  newproperty(:options, :array_matching => :all) do 
    desc "The volume options hash."
    validate do |value|
      raise Puppet::Error, "Puppet::Type::Netapp_volume: options property must be a hash." unless value.is_a? Hash
    end
    
    def insync?(is)
      
    end
  end
end