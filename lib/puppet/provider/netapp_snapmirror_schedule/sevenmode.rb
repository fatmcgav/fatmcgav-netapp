require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_snapmirror_schedule).provide(:sevenmode, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp Snapmirror schedule creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix
  
  # Restrict to 7Mode
  confine :false => begin
    a = Puppet::Node::Facts.indirection
    a.terminus_class = :network_device
    a.find(Puppet::Indirector::Request.new(:facts, :find, "clustered", nil))
  rescue
    :true
  end
  
  netapp_commands :sslist => 'snapmirror-list-schedule'
  
  def create
    Puppet.debug("Puppet::Provider::Netapp_snapmirror_schedule: creating Netapp SnapMirror schedule for Source #{@resource[:source_location]} to Destination #{@resource[:destination_location]}")
    
    # Create a new NaElement object
    req = NaElement.new('snapmirror-set-schedule')
    
    # Add the standard fields
    req.child_add_string('source-location', @resource[:source_location])
    req.child_add_string('destination-location', @resource[:destination_location])
    req.child_add_string('minutes', @resource[:minutes])
    req.child_add_string('hours', @resource[:hours])
    req.child_add_string('days-of-week', @resource[:days_of_week])
    req.child_add_string('days-of-month', @resource[:days_of_month])
    
    # Add the connection-mode tag if populated. 
    if @resource[:connection_mode]
      req.child_add_string('connection-mode', @resource[:connection_mode])
    end
    
    # Add the max-transfer-rate tag if populated. 
    if @resource[:max_transfer_rate]
      req.child_add_string('max-transfer-rate', @resource[:max_transfer_rate])
    end
    
    # Add the restart tag if populated. 
    if @resource[:restart]
      req.child_add_string('restart', @resource[:restart])
    end
    
    # Call webservice to initialize snapmirror relationship. 
    result = transport.invoke_elem(req)

    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_snapmirror_schedule: SnapMirror schedule creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp_snapmirror_schedule schedule creation failed due to #{result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_snapmirror_schedule: SnapMirror schedule created successfully. \n")
      return true
    end
    
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_snapmirror_schedule: destroying Netapp SnapMirror for Source #{@resource[:source_location]} to Destination #{@resource[:destination_location]}")
  end
  
  def exists?
    Puppet.debug("Puppet::Provider::Netapp_snapmirror_schedule: checking status of SnapMirror for Source #{@resource[:source_location]} to Destination #{@resource[:destination_location]}")
    
    # Call webservice to list volume info
    result = sslist('destination-location', @resource[:destination_location])
    Puppet.debug("Puppet::Provider::Netapp_snapmirror_schedule: Checking if schedule exists... \n")
      
    sms_status = result.child_get('snapmirror-schedules')
    if !sms_status
      Puppet.debug("Puppet::Provider::Netapp_snapmirror_schedule: No schedules exist for #{@resource[:source_location]}... \n")
      return false
    else 
      # Should probably check to see if a schedule similar to what we're trying to create already exists?
      # Pull out the schedule-info block. 
      schedule = sms_status.child_get('snapmirror-schedule-info')
      
      # Check if there is a snapmirror-error element first...
      if schedule.child_get('snapmirror-error')
        Puppet.debug("Puppet::Provider::Netapp_snapmirror_schedule: no schedules returned for destination_location #{@resource[:destination_location]}. \n")
        return false
      else  
        destination_location = schedule.child_get_string('destination-location')
        source_location = schedule.child_get_string('source-location')
        minutes = schedule.child_get_string('minutes')
        hours = schedule.child_get_string('hours')
        dow = schedule.child_get_string('days-of-week')
        dom = schedule.child_get_string('days-of-month')
      
        if (source_location == @resource[:source_location] && destination_location == @resource[:destination_location])
          Puppet.debug("Puppet::Provider::Netapp_snapmirror_schedule: schedule exists for destination_location #{@resource[:destination_location]} and source_location #{@resource[:source_location]}. Checking schedule. ")
          if (minutes == @resource[:minutes].to_s && hours == @resource[:hours].to_s && dow == @resource[:days_of_week].to_s && dom == @resource[:days_of_month].to_s)
            Puppet.debug("Puppet::Provider::Netapp_snapmirror_schedule: schedule matches for #{@resource[:destination_location]}.")
            return true
          end
        end
      end
      
      # Got through to here, therefore hasn't matched above. 
      return false
    end
  end
  
end