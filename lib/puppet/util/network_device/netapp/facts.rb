require 'puppet/util/network_device/netapp'

class Puppet::Util::NetworkDevice::Netapp::Facts

  attr_reader :transport

  def initialize(transport)
    @transport = transport
  end

  def retrieve

    # Create empty array
    @facts = {}

    # Invoke "system-get-version" to gather system version.
    result = @transport.invoke("system-get-version")

    # Pull out version
    sys_version = result.child_get_string("version")
    @facts['version'] = sys_version

    if sys_clustered = result.child_get_string("is-clustered") and !sys_clustered.empty?
      @facts['is_clustered'] = sys_clustered
    end

    # Invoke "system-get-info" call to gather system information.
    result = @transport.invoke("system-get-info")

    # Pull out system-info subset.
    sys_info = result.child_get("system-info")

    # Get DNS domainname to build up fqdn
    result = @transport.invoke("options-get", "name", "dns.domainname")
    domain_name = result.child_get_string("value")
    @facts['domain'] = domain_name.downcase

    # Array of values to get
    [
      'system-name',
      'system-id',
      'system-model',
      'system-machine-type',
      'system-serial-number',
      'partner-system-id',
      'partner-serial-number',
      'system-revision',
      'number-of-processors',
      'memory-size',
      'cpu-processor-type',
      'vendor-id',
    ].each do |key|
      @facts[key] = sys_info.child_get_string("#{key}".to_s)
    end

    # cleanup of netapp output to match existing facter key values.
    map = {
      'system-name'          => 'hostname',
      'memory-size'          => 'memorysize_mb',
      'system-model'         => 'productname',
      'cpu-processor-type'   => 'hardwareisa',
      'vendor-id'            => 'manufacturer',
      'number-of-processors' => 'processorcount',
      'system-serial-number' => 'serialnumber',
      'system-id'            => 'uniqueid'
    }
    @facts = Hash[@facts.map {|k, v| [map[k] || k, v] }]\

    # Need to replace '-' with '_'
    @facts = Hash[@facts.map {|k, v| [k.to_s.gsub('-','_'), v] }]
    @facts['memorysize'] = "#{@facts['memorysize_mb']} MB"

    # Set operatingsystem details if present
    if @facts['version'] then
      if @facts['version'] =~ /^NetApp Release (\d.\d(.\d)?\w?)/i
        @facts['operatingsystem'] = 'OnTAP' 
        @facts['operatingsystemrelease'] = $1
      end
    end

    # Handle FQDN
    @facts['hostname'].downcase!
    if @facts['hostname'].include? @facts['domain']
      # Hostname contains the domain, therefore must be FQDN
      @facts['fqdn'] = @facts['hostname']
      @facts['hostname'] = @facts['fqdn'].split('.',1).shift
    else
      # Hostname doesnt include domain.
      @facts['fqdn'] = "#{@facts['hostname']}.#{@facts['domain']}"
    end

    # Return array to calling class.
    @facts
  end
end
