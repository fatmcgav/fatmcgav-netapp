require 'puppet/provider/netapp'

Puppet::Type.type(:netapp_export).provide(:netapp_export, :parent => Puppet::Provider::Netapp) do
  @doc = "Manage Netapp export creation, modification and deletion."
  
  confine :feature => :posix
  defaultfor :feature => :posix

  def create
    Puppet.debug("Puppet::Provider::Netapp_export: creating Netapp export rule #{@resource[:name]} on path #{@resource[:path]}.")
    # Query Netapp to create export against path.
    # Start to construct request
    cmd = NaElement.new("nfs-exportfs-append-rules-2")
    cmd.child_add_string("persistent", true)
    cmd.child_add_string("verbose", true)
    # Add Rules container
    rules = NaElement.new("rules")
    # Construct rule list
    rule_list = NaElement.new("exports-rule-info-2")
    rule_list.child_add_string("pathname", @resource[:path])
    # Add Security container
    security = NaElement.new("security-rules")
    # Construct security rule list
    security_rules = NaElement.new("security-rule-info")
    # Exports must support anon for SMO. Add option to be configurable?
    security_rules.child_add_string("anon", "0")
    # Put it all togeather
    security.child_add(security_rules)
    rule_list.child_add(security)
    rules.child_add(rule_list)
    cmd.child_add(rules)
    # Invoke the constructed request
    result = transport.invoke_elem(cmd)
    #result = transport.invoke("nfs-exportfs-append-rules-2", "persistent", @resource[:persistent], "rules", "pathname", @resource[:path])
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
      Puppet.debug("Puppet::Provider::Netapp_export: export rule #{@resource[:name]} created successfully on path #{@resource[:path]}. \n Response was: #{result.sprintf()} \n")
      return true
    end
  end
  
  def destroy
    Puppet.debug("Puppet::Provider::Netapp_export: destroying Netapp export rule #{@resource[:name]} against path #{@resource[:path]}")
    # Query Netapp to remove export against path. 
    result = transport.invoke("nfs-exportfs-delete-rules", "pathnames", "pathname", @resource[:name], "persistent", @resource[:persistent])
    # Check result returned. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_export: export rule #{@resource[:name]} wasn't destroyed due to #{destroy_result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp export rule #{@resource[:name]} destroy failed due to #{destroy_result.results_reason} \n."
      return false
    else 
      Puppet.debug("Puppet::Provider::Netapp_export: export rule #{@resource[:name]} destroyed successfully. \n")
      return true
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_export: checking existance of Netapp export rule #{@resource[:name]} against path #{@resource[:path]}")
    # Query Netapp for export-list against path. 
    result = transport.invoke("nfs-exportfs-list-rules-2", "pathname", @resource[:path])
    # Check result status. 
    if(result.results_status == "failed")
      Puppet.debug("Puppet::Provider::Netapp_export: nfs-exportfs-list-rules-2 failed due to #{result.results_reason}. \n")
      raise Puppet::Error, "Puppet::Device::Netapp nfs-exportfs-list-rules-2 failed due to #{result.results_reason} \n."
      return false
    else 
      # Get a list of exports
      rule_list = result.child_get("rules")
      rules = rule_list.children_get
      # Itterate through each 'export-info' block. 
      rules.each do |rule|
        # Check if the export name tag matches the resource name we're validating. 
        if(rule.child_get_string("pathname") == @resource[:name])
          # Match found, return true. 
          Puppet.debug("Puppet::Provider::Netapp_export: Matching export rule exists. \n")
          return true
        end
      end
      
      # No match found, therefore doesn't exist. Return false.  
      Puppet.debug("Puppet::Provider::Netapp_export: Matching export rule doesn't exist. \n")
      return false
    end

  end
  
end