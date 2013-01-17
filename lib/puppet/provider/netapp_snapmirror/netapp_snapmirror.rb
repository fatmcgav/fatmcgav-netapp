require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_snapmirror).provide(:netapp_snapmirror, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Snapmirror creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix
  
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
  end
  
  def exists?
    Puppet.debug("Puppet::Provider::Netapp_snapmirror: checking status of SnapMirror for Source #{@resource[:source_location]} to Destination #{@resource[:destination_location]}")
    
    # Call webservice to list volume info
    result = transport.invoke("snapmirror-get-status", "location", @resource[:source_location])
    Puppet.debug("Puppet::Provider::Netapp_snapmirror: Snapmirror status: " + result.sprintf() + "\n")
    # Check response status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_snapmirror: Something went wrong checking for relationship... #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp_snapmirror something went wrong checking for relationship: #{result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_snapmirror: Checking if relationship exists... \n")
      
      sm_status = result.child_get('snapmirror-status')
      if !sm_status
        Puppet.debug("Puppet::Provider::Netapp_snapmirror: No relationship exist for #{@resource[:source_location]}... \n")
        return false
      else 
        # Should probably check to see if a relationship similar to what we're trying to create already exists?
        relationships = sm_status.children_get
        
        # Itterate through the relationships for this source_location. 
        relationships.each do |relationship|
          source_location = relationship.child_get_string('source-location')
          destination_location = relationship.child_get_string('destination-location')
          
          if (source_location == @resource[:source_location] && destination_location == @resource[:destination_location])
            Puppet.debug("Puppet::Provider::Netapp_snapmirror: relationship already exists for source_location #{@resource[:source_location]} and destination_location #{@resource[:destination_location]}. ")
            return true
          end
        end
      end
      
      # Got through to here, therefore hasn't matched above. 
      return false
    end
  end
  
end