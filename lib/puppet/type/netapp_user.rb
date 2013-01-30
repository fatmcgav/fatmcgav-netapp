Puppet::Type.newtype(:netapp_user) do 
  @doc = "Manage Netapp User creation, modification and deletion."
  
  apply_to_device
  
  ensurable do
    desc "Netapp User resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
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
    desc "The user password. Minimum length is 8 characters, must contain atleast one number."
    validate do |value|
      unless value =~ /^\S{8,}$/
        raise ArgumentError, "%s is not a valid password." % value
      end
    end
  end
  
  newparam(:fullname) do
    desc "The user full name."
    validate do |value|
      unless value =~ /^\w+\s?\w+$/
         raise ArgumentError, "%s is not a valid full name." % value
      end
    end
  end

  newparam(:comment) do
    desc "User comment"
    validate do |value|
      unless value =~ /^[\w\s\-\.]+$/
         raise ArgumentError, "%s is not a valid comment." % value
      end
    end
  end
  
  newparam(:passminage) do
    desc "Number of days that this user's password must be active before the user can change it. Default value is 0. "
    defaultto '0'
    validate do |value|
      unless value =~ /^\d+$/
         raise ArgumentError, "%s is not a valid password minimum age." % value
      end
    end
  end
  
  newparam(:passmaxage) do
    desc "Number of days that this user's password can be active before the user must change it. Default value is 2^31-1 days. "
    validate do |value|
      unless value =~ /^\d+$/
         raise ArgumentError, "%s is not a valid password maximum age." % value
      end
    end
  end
  
  newparam(:status) do
    desc "Status of user account. Valid values are: enabled, disabled and expired. "
    newvalues(:enabled, :disabled, :expired)
    defaultto(:enabled)
  end
  
  newparam(:groups) do
    desc "List of groups for this user account. Comma seperate multiple values. "
  end
  
end
