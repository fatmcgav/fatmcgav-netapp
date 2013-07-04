require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_export).provide(:netapp_export, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp export creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  netapp_commands :elist => 'nfs-exportfs-list-rules-2'
  
  mk_resource_methods

  def self.instances
    Puppet.debug("Puppet::Provider::Netapp_export: got to self.instances.")
    exports = []

    # Get a list of all nfs export rules
    result = elist

    # Get a list of exports
    rule_list = result.child_get("rules")
    rules = rule_list.children_get()
    # Itterate through each 'export-info' block.
    rules.each do |rule|
      name = rule.child_get_string("pathname")
      Puppet.debug("Puppet::Provider::Netapp_export.prefetch: Processing rule for export #{name}. \n")
      
      # Construct an export hash for rule
      export = { :name => name,
                 :ensure => :present }
      
      # Add the actual filer path if present.
      export[:path] = rule.child_get_string("actual-pathname") unless rule.child_get_string("actual-pathname").nil?
      
      # Pull out security rules block
      security_rules = rule.child_get("security-rules")
      security_rule_info = security_rules.child_get("security-rule-info")
      
      # Add Anon value to export
      anon = security_rule_info.child_get_string("anon")
      export[:anon] = anon
      
      # Placeholders to be populated as required...
      ro_hosts = []
      rw_hosts = []
      
      # Pull read-only rules...
      read_only = security_rule_info.child_get("read-only")
      unless read_only.nil?
        Puppet.debug("Processing read-only security rules. \n")
        read_only_hosts = read_only.children_get()
        read_only_hosts.each do |ro_export|
          ro_host_name = ro_export.child_get_string("name")
          ro_all_hosts = ro_export.child_get_string("all-hosts")
          Puppet.debug("Read-only: Name = #{ro_host_name}, All hosts = #{ro_all_hosts} \n")
          if ro_all_hosts
          Puppet.debug("All_hosts = #{ro_all_hosts} \n")
            export[:readonly] = ['all_hosts']
          else
            Puppet.debug("Processing hostname records... \n")
            ro_hosts << ro_host_name
          end
        end
      end
      
      # Pull read-write rules
      read_write = security_rule_info.child_get("read-write")
      unless read_write.nil?
        Puppet.debug("Processing read-write security rules. \n")
        read_write_hosts = read_write.children_get()
        read_write_hosts.each do |rw_export|
          rw_host_name = rw_export.child_get_string("name")
          rw_all_hosts = rw_export.child_get_string("all-hosts")
          Puppet.debug("Read-write: Name = #{rw_host_name}, All hosts = #{rw_all_hosts} \n")
          if rw_all_hosts
            Puppet.debug("All_hosts = #{rw_all_hosts} \n")
            export[:readwrite] = ['all_hosts']
          else
            Puppet.debug("Processing hostname_records... \n")
            rw_hosts << rw_host_name
          end
        end
      end
  
      Puppet.debug("Processed all fields. Adding to export if required... ")
      # Add ro_hosts and rw_hosts if not empty
      export[:readonly] = ro_hosts unless ro_hosts.empty?
      export[:readwrite] = rw_hosts unless rw_hosts.empty?
  
      # Create the instance and add to exports array.
      Puppet.debug("Creating instance for #{name}. \n")
      exports << new(export)
    end
  
    # Return the final exports array. 
    Puppet.debug("Returning exports array. ")
    exports
  end
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::Netapp_export: Got to self.prefetch.")
    # Itterate instances and match provider where relevant.
    instances.each do |prov|
      Puppet.debug("Prov.name = #{resources[prov.name]}. ")
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def flush
    Puppet.debug("Puppet::Provider::Netapp_export: Got to flush for resource #{@resource[:name]}.")
    
    # Check required resource state
    Puppet.debug("Property_hash ensure = #{@property_hash[:ensure]}")
    case @property_hash[:ensure]
    when :absent
      Puppet.debug("Puppet::Provider::Netapp_export: Ensure is absent.")
      
      # Query Netapp to remove export against path. 
      cmd = NaElement.new("nfs-exportfs-delete-rules")
      cmd.child_add_string("persistent", @resource[:persistent].to_s)
      
      # Add Pathnames container
      paths = NaElement.new("pathnames")
      pathnames = NaElement.new("pathname-info")
      pathnames.child_add_string("name", @resource[:name])
      paths.child_add(pathnames)
      cmd.child_add(paths)
      Puppet.debug("Destroy command xml looks like: \n #{cmd.sprintf()}")
      
      # Invoke the constructed request
      result = transport.invoke_elem(cmd)
  
      # Check result returned. 
      if(result.results_status == "failed")
        Puppet.debug("Puppet::Provider::Netapp_export: export rule #{@resource[:name]} wasn't destroyed due to #{result.results_reason}. \n")
        raise Puppet::Error, "Puppet::Device::Netapp export rule #{@resource[:name]} destroy failed due to #{result.results_reason} \n."
        return false
      else 
        Puppet.debug("Puppet::Provider::Netapp_export: export rule #{@resource[:name]} destroyed successfully. \n")
        return true
      end
    
    when :present
    
      Puppet.debug("Puppet::Provider::Netapp_export: Ensure is present.")
      
      # Query Netapp to create export against path.
      # Start to construct request
      cmd = NaElement.new("nfs-exportfs-modify-rule-2")
      cmd.child_add_string("persistent", @resource[:persistent].to_s)
        
      # Add Rules container
      rule = NaElement.new("rule")
      # Construct rule list
      rule_list = NaElement.new("exports-rule-info-2")
      rule_list.child_add_string("pathname", @resource[:name])
      rule_list.child_add_string("actual-pathname", @resource[:path]) unless @resource[:path].nil?
      
      # Add Security container
      security = NaElement.new("security-rules")
      # Construct security rule list
      security_rules = NaElement.new("security-rule-info")
      # Exports must support anon for SMO. Add option to be configurable?
      security_rules.child_add_string("anon", @resource[:anon])
        
      # Add host security if required
      # Read-write
      unless @resource[:readwrite].nil?
        readwrite = NaElement.new("read-write")
        Puppet.debug("Got a readwrite array. Checking if all_hosts... First record = #{@resource[:readwrite].first} \n")
        if @resource[:readwrite].first == 'all_hosts'
          hostname_info = NaElement.new("exports-hostname-info")
          hostname_info.child_add_string("all-hosts", "true")
          readwrite.child_add(hostname_info)
        else
          @resource[:readwrite].each do |host|
            hostname_info = NaElement.new("exports-hostname-info")
            hostname_info.child_add_string("name", host)
            readwrite.child_add(hostname_info)
          end
        end
        security_rules.child_add(readwrite)
      end
      # Read-only
      unless @resource[:readonly].nil?
        readonly = NaElement.new("read-only")
        Puppet.debug("Got a readonly array. Checking if all_hosts... First record = #{@resource[:readonly].first} \n")
        if @resource[:readonly].first == 'all_hosts'
          hostname_info = NaElement.new("exports-hostname-info")
          hostname_info.child_add_string("all-hosts", "true")
          readonly.child_add(hostname_info)
        else
          @resource[:readonly].each do |host|
            hostname_info = NaElement.new("exports-hostname-info")
            hostname_info.child_add_string("name", host)
            readonly.child_add(hostname_info)
          end
        end
        security_rules.child_add(readonly)
      end
      
      # Put it all togeather
      security.child_add(security_rules)
      rule_list.child_add(security)
      rule.child_add(rule_list)
      cmd.child_add(rule)
      Puppet.debug("Modify command xml looks like: \n #{cmd.sprintf()}")
      
      # Invoke the constructed request
      result = transport.invoke_elem(cmd)
  
      # Check result status
      if(result.results_status == "failed")
        Puppet.debug("Puppet::Provider::Netapp_export: export rule #{@resource[:name]} modification failed due to #{result.results_reason}. \n")
        raise Puppet::Error, "Puppet::Device::Netapp export rule #{@resource[:name]} modification failed due to #{result.results_reason} \n."
        return false
      else
        # Passed above, therefore must of worked.
        Puppet.debug("Puppet::Provider::Netapp_export: export rule #{@resource[:name]} modified successfully on path #{@resource[:path]}. \n")
        return true
      end
      
    end #EOC
  end
  
  def create
    Puppet.debug("Puppet::Provider::Netapp_export: creating Netapp export rule #{@resource[:name]} on path #{@resource[:path]}.")
    
    # Query Netapp to create export against path.
    # Start to construct request
    cmd = NaElement.new("nfs-exportfs-append-rules-2")
    cmd.child_add_string("persistent", @resource[:persistent].to_s)
    cmd.child_add_string("verbose", "true")
    
    # Add Rules container
    rules = NaElement.new("rules")
    # Construct rule list
    rule_list = NaElement.new("exports-rule-info-2")
    rule_list.child_add_string("pathname", @resource[:name])
    rule_list.child_add_string("actual-pathname", @resource[:path]) unless @resource[:path].nil?
    
    # Add Security container
    security = NaElement.new("security-rules")
    # Construct security rule list
    security_rules = NaElement.new("security-rule-info")
    # Exports must support anon for SMO. Add option to be configurable?
    security_rules.child_add_string("anon", @resource[:anon])
    
    # Add host security if required
    # Read-write
    unless @resource[:readwrite].nil?
      readwrite = NaElement.new("read-write")
      if @resource[:readwrite].first == 'all_hosts'
        hostname_info = NaElement.new("exports-hostname-info")
        hostname_info.child_add_string("all-hosts", "true")
        readwrite.child_add(hostname_info)
      else
        @resource[:readwrite].each do |host|
          hostname_info = NaElement.new("exports-hostname-info")
          hostname_info.child_add_string("name", host)
          readwrite.child_add(hostname_info)
        end
      end
      security_rules.child_add(readwrite)
    end
    # Read-only
    unless @resource[:readonly].nil?
      readonly = NaElement.new("read-only")
      Puppet.debug("Got a readonly array. Checking if all_hosts... First record = #{@resource[:readonly].first} \n")
      if @resource[:readonly].first == 'all_hosts'
        hostname_info = NaElement.new("exports-hostname-info")
        hostname_info.child_add_string("all-hosts", "true")
        readonly.child_add(hostname_info)
      else
        @resource[:readonly].each do |host|
          hostname_info = NaElement.new("exports-hostname-info")
          hostname_info.child_add_string("name", host)
          readonly.child_add(hostname_info)
        end
      end
      security_rules.child_add(readonly)
    end
    
    # Put it all togeather
    security.child_add(security_rules)
    rule_list.child_add(security)
    rules.child_add(rule_list)
    cmd.child_add(rules)
    Puppet.debug("Create command xml looks like: \n #{cmd.sprintf()}")
    
    # Invoke the constructed request
    result = transport.invoke_elem(cmd)

    # Check result status
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_export: export rule #{@resource[:name]} creation failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp export rule #{@resource[:name]} creation failed due to #{result.results_reason} \n."
      return false
    else
      # Work-around defect in NetApp SDK, whereby command will pass, even if export is not valid. 
      output = result.child_get("loaded-pathnames")
      loaded_paths = output.child_get("pathname-info")
      # Check if var is actually null. 
      if(loaded_paths.nil?)
        Puppet.debug("Puppet::Provider::Netapp_export: export rule #{@resource[:name]} creation failed. \n")
        raise Puppet::Error, "Puppet::Provider::Netapp_export: export rule #{@resource[:name]} creation failed. Verify settings. \n"
        return false
      end
      # Passed above, therefore must of worked. 
      Puppet.debug("Puppet::Provider::Netapp_export: export rule #{@resource[:name]} created successfully on path #{@resource[:path]}. \n")
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_export: destroying Netapp export rule #{@resource[:name]} against path #{@resource[:path]}")
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_export: checking existance of Netapp export rule #{@resource[:name]}.")
    @property_hash[:ensure] == :present
  end

  
end