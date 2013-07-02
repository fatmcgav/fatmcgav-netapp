Puppet::Type.newtype(:netapp_export) do 
  @doc = "Manage Netapp NFS Export creation, modification and deletion."
  
  apply_to_device
  
  ensurable
  
  newparam(:name) do
    desc "The export path. Valid format is /vol/[volume_name](/[qtree_name])."
    isnamevar
    validate do |value|
    	unless value =~ /^(\/[\w]+){2,3}$/
        raise ArgumentError, "%s is not a valid export name." % value
      end
    end
  end

  newparam(:persistent) do
    desc "Should this be a persistent export? Defaults to true."
    newvalues(:true, :false)
    defaultto(:true)
  end
  
  newparam(:path) do
    desc "The filer path to export. If not specified, uses :name value"
    validate do |value|
    	unless value =~ /^(\/[\w]+){2,3}$/
        raise ArgumentError, "%s is not a valid export filer path." % value
      end
    end
  end
  
  newproperty(:anon) do 
    desc "Should the export support anonymous root access."
    defaultto '0'
    validate do |value|
      raise ArgumentError, "Anon should be a string." unless value.is_a?String
    end
    
    def insync?(is)
      # Should is an array, so pull first value.
      should = @should.first

      return false unless is == should

      # Got here, so must match
      return true

    end
  end
  
  newproperty(:readonly, :array_matching => :all) do
    desc "Export read-only hosts."

    def insync?(is)
      # Check that is is an array
      return false unless is.is_a? Array

      # Check the first value to see if 'all_hosts'.
      if is.first == 'all_hosts' && @should.first == 'all_hosts'
        return true
      else
        # If they were different lengths, they are not equal.
        return false unless is.length == @should.length

        # Check that is and @should are the same...
        return (is == @should or is == @should.map(&:to_s))

      end
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end

  newproperty(:readwrite, :array_matching => :all) do
    desc "Export read-write hosts. Defaults to 'all_hosts'."
    defaultto ['all_hosts']
    
    def insync?(is)
      # Check that is is an array
      return false unless is.is_a? Array

      # Check the first value to see if 'all_hosts'.
      if is.first == 'all_hosts' && @should.first == 'all_hosts'
        return true
      else
        Puppet.debug("Is and Should are hostname arrays... ")
        # If they were different lengths, they are not equal.
        return false unless is.length == @should.length

        # Check that is and @should are the same...
        return (is == @should or is == @should.map(&:to_s))

      end
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
  end
  
  # Make sure that ReadOnly and ReadWrite aren't the same values. 
  validate do
    raise ArgumentError, "Readonly and Readwrite params cannot be the same." if self[:readwrite] == self[:readonly]
  end
  
  autorequire(:netapp_volume) do
    # Check if we've got a path
    if self[:path].nil?
      Puppet.debug("No :path value, so use :name.")
      # Pull out some vars
      resource = self[:name][self[:name].rindex('/')+1..-1]
      count = self[:name].count("/")
      Puppet.debug("Resource = #{resource}, Count = #{count}")
      # Check if this is a volume or qtree
      if count == 2
        # Got a volume, therefore add the resource require.
        Puppet.debug("Got a volume, adding resource require.")
        resource
      else
        # Got a qtree, therefore nothing to add.
        Puppet.debug("Got a qtree, no resources to require.") 
        nil
      end
    else
      Puppet.debug("Got a :path value.")
      # Pull out some vars
      resource = self[:path][self[:path].rindex('/')+1..-1]
      count = self[:path].count("/")
      Puppet.debug("Resource = #{resource}, Count = #{count}")
      # Check if this is a volume or qtree
      if count == 2
        # Got a volume, therefore add the resource require.
        Puppet.debug("Got a volume, adding resource require.")
        resource
      else
        # Got a qtree, therefore nothing to add.
        Puppet.debug("Got a qtree, no resources to require.") 
        nil
      end
    end
  end
  
  autorequire(:netapp_qtree) do
    # Check if we've got a path
    if self[:path].nil?
      Puppet.debug("No :path value, so use :name.")
      # Pull out some vars
      resource = self[:name][self[:name].rindex('/')+1..-1]
      count = self[:name].count("/")
      Puppet.debug("Resource = #{resource}, Count = #{count}")
      # Check if this is a volume or qtree
      if count == 3
        # Got a volume, therefore add the resource require.
        Puppet.debug("Got a qtree, adding resource require.")
        resource
      else
        # Got a qtree, therefore nothing to add.
        Puppet.debug("Got a volume, no resources to require.") 
        nil
      end
    else
      Puppet.debug("Got a :path value.")
      # Pull out some vars
      resource = self[:path][self[:path].rindex('/')+1..-1]
      count = self[:path].count("/")
      Puppet.debug("Resource = #{resource}, Count = #{count}")
      # Check if this is a volume or qtree
      if count == 3
        # Got a volume, therefore add the resource require.
        Puppet.debug("Got a qtree, adding resource require.")
        resource
      else
        # Got a qtree, therefore nothing to add.
        Puppet.debug("Got a volume, no resources to require.") 
        nil
      end
    end
  end
  
end
