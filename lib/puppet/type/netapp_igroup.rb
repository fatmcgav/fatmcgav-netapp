Puppet::Type.newtype(:netapp_igroup) do 
  @doc = "Manage Netapp iGroup create and destroy."
  
  apply_to_device
  
  ensurable

  newparam(:name) do
    desc "Name of the iGroup"
  end

  newparam(:initiatorgrouptype) do
    desc "Type of the initiator group" 
    newvalues(:fcp, :mixed, :iscsi)
  end
  
  newparam(:ostype) do 
    desc "OS type of the initiators within the group"
  end
  
   newparam(:force, :boolean => false) do
    desc "Forcibly destroys the iGroup, disabling mapping conflict checks with the high-availability partner."
    newvalues(:true, :false)
    defaultto :false
  end
  
end
