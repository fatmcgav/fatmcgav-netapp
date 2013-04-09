Puppet::Type.newtype(:netapp_group) do 
  @doc = "Manage Netapp Group creation, modification and deletion."
  
  apply_to_device
  
  ensurable do
    desc "Netapp Group resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
  newparam(:groupname) do
    desc "The group name."
    isnamevar
    validate do |value|
      unless value =~ /^[\w-]+$/
         raise ArgumentError, "%s is not a valid group name." % value
      end
    end
  end

  newparam(:comment) do
    desc "Group comment"
    validate do |value|
      unless value =~ /^[\w\s\-\.]+$/
         raise ArgumentError, "%s is not a valid comment." % value
      end
    end
  end
  
  newproperty(:roles) do
    desc "List of roles for this group. Comma separate multiple values. "
    
    def insync?(is)
      # @should is an Array. see lib/puppet/type.rb insync?
      should = @should.first

      # Split is and should into arrays on ,
      should_arr = should.split(',')
      is_arr = is.split(',')
      
      # Comparison of arrays
      return false unless is_arr.class == Array and should_arr.class == Array
      # Should is master, therefore any difference needs correction
      unless (should_arr - is_arr).empty?
        return false
      end
      # Got here, so must match
      return true
    end
    
  end
  
end
