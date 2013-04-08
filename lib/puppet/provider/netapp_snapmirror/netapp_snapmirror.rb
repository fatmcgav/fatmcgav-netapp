require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_snapmirror).provide(:netapp_snapmirror, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Snapmirror creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix
  
  mk_resource_methods
  
  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_snapmirror: got to self.instances.")
    
    snapmirror_instances = Array.new
    
    # Query Netapp for snapmirror list. 
    result = transport.invoke('snapmirror-get-status')
    # Check result status.
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_snapmirror: Snapmirror-get-status failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp_snapmirror: Snapmirror-get-status failed due to #{result.results_reason}. \n."
      return false
    else 
      # Pull list of snapmirror-status blocks
      snapmirror_list = result.child_get('snapmirror-status')
      snapmirror_instances = snapmirror_list.children_get()
      
      # Iterate array
      snapmirror_instances.each do |snapmirror|
        # Pull out the destination location value
        destination_location = snapmirror.child_get_string('destination-location')
        Puppet.debug("Puppet::Provider::Netapp_snapmirror: Processing snapmirror relatioship for destination #{destination_location}.")
        
        # Create hash of information 
        snapmirror_info = { :destination_location => destination_location,
                            :ensure => :present }
                            
        # Create the instance and add to snapmirror instances array
        Puppet.debug("Creating instance for '#{destination_location}.")
        snapmirror_instances << new(snapmirror_info)
      end
      
      # Return the final user array. 
      Puppet.debug("Returning snapmirror array. ")
      snapmirror_instances
    end
  end
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_snapmirror: Got to self.prefetch.")
    # Iterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end
  
  def create
    Puppet.debug("Puppet::Provider::Netapp_snapmirror: creating Netapp SnapMirror relationship for Source #{@resource[:source_location]} to Destination #{@resource[:destination_location]}")
    
    # Create a new NaElement object
    req = NaElement.new('snapmirror-initialize')
    
    # Add the standard fields
    req.child_add_string('source-location', @resource[:source_location])
    req.child_add_string('destination-location', @resource[:destination_location])
    
    # Add the source snapshot tag if populated. 
    if @resource[:source_snapshot]
      req.child_add_string('source-snapshot', @resource[:source_snapshot])
    end
      
    # Add the destination snapshot tag if populated. 
    if @resource[:destination_snapshot]
      req.child_add_string('destination-snapshot', @resource[:destination_snapshot])
    end
    
    # Add the max-transfer-rate tag if populated. 
    if @resource[:max_transfer_rate]
      req.child_add_string('max-transfer-rate', @resource[:max_transfer_rate])
    end
    
    # Call webservice to initialize snapmirror relationship. 
    result = transport.invoke_elem(req)

    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_snapmirror: SnapMirror relationship creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp_snapmirror relationship creation failed due to #{result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_snapmirror: SnapMirror relationship created successfully. \n")
      return true
    end
    
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_snapmirror: destroying Netapp SnapMirror for Source #{@resource[:source_location]} to Destination #{@resource[:destination_location]}")
    @property_hash[:ensure] = :absent
  end
  
  def exists?
    Puppet.debug("Puppet::Provider::Netapp_snapmirror: checking existence of SnapMirror for Source #{@resource[:source_location]} to Destination #{@resource[:destination_location]}")
    @property_hash[:ensure] == :present
  end
  
end