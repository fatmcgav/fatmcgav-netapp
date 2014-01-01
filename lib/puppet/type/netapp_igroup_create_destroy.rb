Puppet::Type.newtype(:netapp_igroup_create_destroy) do 
  @doc = "Manage Netapp iGroup create and destroy."
  
  apply_to_device
  
  ensurable

  newparam(:name) do
    desc "Name of the iGroup"
  end

  newparam(:initiatorgrouptype) do
    desc "Type of the initiator group" 
  end
  
  newparam(:ostype) do 
    desc "OS type of the initiators within the group"
  end
  
end

