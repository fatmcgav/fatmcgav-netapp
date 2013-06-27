require 'spec_helper'
require 'puppet/provider/netapp'

describe Puppet::Provider::Netapp do
  let(:netapp_prov_obj) { described_class.new }

  describe "transport method" do
    it "with uninitialized device and no url should return error" do
      expect { netapp_prov_obj.transport }.to(
        raise_error(Puppet::Error, /^Puppet::Util::NetworkDevice::Netapp: device not initialized/)
      )
    end

    it "with uninitialized device and a unresolvable url should return error" do
      # the NetApp Device expects a filer instead of a traditional url
      Facter.expects(:value).with(:url).twice.returns('filer.example.com')
      Puppet::Util::NetworkDevice::Netapp::Device.expects(:configfile).returns my_fixture('netapp.yml')
      expect { netapp_prov_obj.transport }.to(
        raise_error(Puppet::Error, /invoke system-get-version failed/)
      )
    end
  end
end
