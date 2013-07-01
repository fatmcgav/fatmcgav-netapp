Puppet::Type.newtype(:netapp_group) do 
  @doc = "Manage Netapp Group creation, modification and deletion."
  
  apply_to_device
  
  ensurable
  
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
    
    validate do |value|
      unless value =~ /^[\w\s\-]+(,?[\w\s\-]*)*$/
         raise ArgumentError, "%s is not a valid role list." % value
      end
    end
    
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
  
  autorequire(:netapp_role) do 
    self[:roles].split(',')
  end
  
end
