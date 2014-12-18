Puppet::Type.newtype(:netapp_user) do 
  @doc = "Manage Netapp User creation, modification and deletion."
  
  apply_to_device
  
  ensurable
  
  newparam(:username) do
    desc "The user username."
    isnamevar
    validate do |value|
      unless value =~ /^[\w-]+$/
         raise ArgumentError, "%s is not a valid username." % value
      end
    end
  end
  
  newparam(:password) do
    desc "The user password. Minimum length is 8 characters, must contain at-least one number."
    validate do |value|
      unless value =~ /^\S{8,}$/
        raise ArgumentError, "%s is not a valid password." % value
      end
    end
  end
  
  newproperty(:fullname) do
    desc "The user full name."
    validate do |value|
      unless value =~ /^[\w+\s]+$/
         raise ArgumentError, "%s is not a valid full name." % value
      end
    end
  end

  newproperty(:comment) do
    desc "User comment"
    validate do |value|
      unless value =~ /^[\w\s\-\.]+$/
         raise ArgumentError, "%s is not a valid comment." % value
      end
    end
  end
  
  newproperty(:passminage) do
    desc "Number of days that this user's password must be active before the user can change it. Default value is 0. "
    defaultto '0'
    validate do |value|
      raise ArgumentError, "%s is not a valid password minimum age." % value unless value =~ /^\d+$/
      raise ArgumentError, "Passminage must be between 0 and 4294967295." unless value.to_i.between?(0,4294967295)
    end
    
    munge do |value|
      case value
      when String
        if value =~ /^[-0-9]+$/
          value = Integer(value)
        end
      end

      return value
    end
  end
  
  newproperty(:passmaxage) do
    desc "Number of days that this user's password can be active before the user must change it. Default value is 2^31-1 days. "
    defaultto '4294967295'
    validate do |value|
      raise ArgumentError, "%s is not a valid password maximum age." % value unless value =~ /^\d+$/
      raise ArgumentError, "Passmaxage must be between 0 and 4294967295." unless value.to_i.between?(0,4294967295)
    end
    
    munge do |value|
      case value
      when String
        if value =~ /^[-0-9]+$/
          value = Integer(value)
        end
      end

      return value
    end
  end
  
  newparam(:status) do
    desc "Status of user account. Valid values are: enabled, disabled and expired. Cannot be modified via API. "
    newvalues(:enabled, :disabled, :expired)
    defaultto(:enabled)
  end
  
  newproperty(:groups) do
    desc "List of groups for this user account. Comma separate multiple values. "
    isrequired
    
    validate do |value|
      unless value =~ /^[\w\s\-]+(,?[\w\s\-]*)*$/
         raise ArgumentError, "%s is not a valid group list." % value
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
  
  autorequire(:netapp_group) do 
    self[:groups].split(',') if self[:groups]
  end
  
end

