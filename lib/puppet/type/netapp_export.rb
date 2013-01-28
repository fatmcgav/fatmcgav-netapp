Puppet::Type.newtype(:netapp_export) do 
  @doc = "Manage Netapp NFS Export creation, modification and deletion."
  
  apply_to_device
  
  ensurable do
    desc "Netapp NFS Export resource state. Valid values are: present, absent."
    
    defaultto(:present)
    
    newvalue(:present) do 
      provider.create
    end
    
    newvalue(:absent) do 
      provider.destroy
    end
  end
  
  newparam(:name) do
    desc "The export name. Valid format is /vol/[volume_name](/[qtree_name])."
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
    defaultto { @resource[:name] }
    validate do |value|
    	unless value =~ /^(\/[\w]+){2,3}$/
        	raise ArgumentError, "%s is not a valid export filer path." % value
        end
    end
  end
  
end
