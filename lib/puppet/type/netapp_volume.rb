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
  
  newparam(:name) do
    desc "The volume name."
    isnamevar
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
  
  newproperty(:snapreserve) do 
    desc "The percentage of space to reserve for snapshots."
    validate do |value|
      raise Puppet::Error, "Puppet::Type::Netapp_volume: Reserved percentage must be between 0 and 100." unless value.to_i.between?(0,100)
    end 
  end
  
  newproperty(:options, :array_matching => :all) do 
    desc "The volume options hash."
    validate do |value|
      raise Puppet::Error, "Puppet::Type::Netapp_volume: options property must be a hash." unless value.is_a? Hash
    end
    
    def insync?(is)
      # @should is an Array. see lib/puppet/type.rb insync?
      should = @should.first

      # Comparison of hashes
      return false unless is.class == Hash and should.class == Hash
      should.each do |k,v|
        return false unless is[k] == should[k]
      end
      true
    end
    
    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end
end