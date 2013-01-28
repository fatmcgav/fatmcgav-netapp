require 'spec_helper'
require 'puppet/provider/netapp'

describe Puppet::Provider::Netapp do
  let(:netapp_prov_obj) { Puppet::Provider::Netapp.new }

  describe "transport method" do
      it "with uninitialized device and no url should return error" do
        expect { netapp_prov_obj.transport }.to(
          raise_error(Puppet::Error, /^Puppet::Util::NetworkDevice::Netapp: device not initialized/)
        )
      end
  
      it "with uninitialized device and a unresolvable url should return error" do
        Facter.expects(:value).with(:url).twice.returns("https://myuser:mypass@mockurl/")
        expect { netapp_prov_obj.transport }.to(
          raise_error(SocketError, /^getaddrinfo: nodename nor servname provided, or not known/)
        )
      end
  
    end
    
end