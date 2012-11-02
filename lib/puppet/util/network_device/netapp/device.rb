require 'puppet/util/network_device/netapp/facts'
require 'puppet/util/network_device/netapp/NaServer'
require 'yaml'

class Puppet::Util::NetworkDevice::Netapp::Device

	attr_accessor :filer

	def initialize(filer)

		Puppet.debug("Puppet::Device::Netapp: connecting to Netapp device #{filer}.")
		#This should work to find the configdir
		configdir = Puppet[:configdir]
		Puppet.debug("Puppet::Device::Netapp: configdir is #{configdir}.")

		configfile = File.read(configdir+"/netapp.yml")
		filerconfig = Yaml.load(configfile)[filer]
		username = filerconfig[:user]
		password = filerconfig[:password]

		@transport ||= NaServer.new(filer)
		@transport.set_admin_user(username, password)
		@transport.set_transport_type("HTTPS")
		
		# Test interface
		result = @transport.invoke("system-get-version")
		version = result.child_get_string("version")
		Puppet.debug("Puppet::Device::NetApp: Verion = $version")

