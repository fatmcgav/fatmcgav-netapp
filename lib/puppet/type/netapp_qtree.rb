require 'puppet/util/network_device'

Puppet::Type.newtype(:netapp_qtree) do 
  @doc = "Manage Netapp Qtree creation, modification and deletion."
  
  apply_to_device
  
  ensurable
  
  newparam(:name) do
    desc "The qtree name."
    isnamevar
    validate do |value|
      unless value =~ /^[\w\-]+$/
         raise ArgumentError, "%s is not a valid qtree name." % value
      end
    end
  end

  newparam(:volume) do
    desc "The volume to create qtree against."
    validate do |value|
      unless value =~ /^\w+$/
         raise ArgumentError, "%s is not a valid volume name." % value
      end
    end   
  end

  autorequire(:netapp_volume) do
    self[:volume]
  end
end
