require 'puppet/util/network_device'
require 'puppet/util/network_device/netapp/facts'
require 'puppet/util/network_device/netapp/NaServer'
require 'yaml'

class Puppet::Util::NetworkDevice::Netapp::Device

	attr_accessor :filer, :transport

	def initialize(filer)

		Puppet.debug("Puppet::Device::Netapp: connecting to Netapp device #{filer}.")
		#This should work to find the configdir
		configdir = Puppet[:confdir]
		Puppet.debug("Puppet::Device::Netapp: configdir is #{configdir}.")

		configfile = File.read(configdir+"/netapp.yml")
		filerconfig = YAML.load(configfile)[filer]
		username = filerconfig[:user]
		password = filerconfig[:password]
    if(username == nil || password == nil)
      raise Puppet::Error, "Puppet::Device::Netapp username or password for #{filer} are null."
    else
      Puppet.debug("Puppet::Device::Netapp: config read. User = #{username}.")
    end

		@transport ||= NaServer.new(filer, 1, 13)
		@transport.set_admin_user(username, password)
		@transport.set_transport_type("HTTPS")
		
		# Test interface
		result = @transport.invoke("system-get-version")
    if(result.results_errno() != 0)
      r = result.results_reason()
      raise Puppet::Error, "Puppet::Device::Netapp: invoke system-get-version failed : \n #{r} \n"
    else
      version = result.child_get_string("version")
      Puppet.debug("Puppet::Device::Netapp: Verion = #{version}")
    end
   end
		
  def facts
    @facts ||= Puppet::Util::NetworkDevice::Netapp::Facts.new(@transport)
    facts = @facts.retreive
    
    facts
  
  end

end