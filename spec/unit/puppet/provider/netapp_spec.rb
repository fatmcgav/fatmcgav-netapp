require 'spec_helper'
require 'puppet/provider/netapp'

describe Puppet::Provider::Netapp do
  let(:netapp_prov_obj) { described_class.new }

  let :result_success do
    n = NaElement.new("results")
    n.attr_set("status", "passed")
    n
  end

  let :result_failed do
    n = NaElement.new("results")
    n.attr_set("status", "failed")
    n.attr_set("reason", "Authorization failed")
    n.attr_set("errno", 13001)
    n
  end

  describe "transport method" do
    it "with uninitialized device and no url should return error" do
      expect { netapp_prov_obj.transport }.to(
        raise_error(Puppet::Error, /^Puppet::Util::NetworkDevice::Netapp: device not initialized/)
      )
    end

    it "with uninitialized device and a unresolvable url should return error" do
      # the NetApp Device expects a filer instead of a traditional url
      Facter.expects(:value).with(:url).twice.returns('filer.example.com')
      expect { netapp_prov_obj.transport }.to raise_error(ArgumentError)
    end
  end

  describe "netapp_commands" do
    let :provider do
      type = Puppet::Type.newtype(:netapp_dummy_type)
      provider = type.provide(:netapp_dummy_provider, :parent => described_class) do
        netapp_commands :qadd => 'qtree-create', :qdel => 'qtree-delete'
        def self.transport
          @transport ||= NaServer.new("test.example.com",1,12)
        end
      end
    end

    it "should create a class and an instance method" do
      provider.should respond_to(:qadd)
      provider.new.should respond_to(:qadd)
    end

    it "should execute the corresponding api call" do
      provider.transport.expects(:invoke).with("qtree-create").returns result_success
      provider.qadd.should == result_success
    end

    it "should pass all arguments to the api call" do
      provider.transport.expects(:invoke).with("qtree-create", 'qtree', 'q1', 'volume', 'vol1').returns result_success
      provider.qadd('qtree', 'q1', 'volume', 'vol1').should == result_success
    end

    it "should log the api call in debug mode" do
      provider.transport.expects(:invoke).with("qtree-create", 'qtree', 'q1').returns result_success
      provider.expects(:debug).with 'Executing api call qtree-create qtree q1'
      provider.qadd('qtree', 'q1').should == result_success
    end

    it "should raise an error if api call fails" do
      provider.transport.expects(:invoke).with("qtree-create", 'qtree', 'q1').returns result_failed
      expect { provider.qadd 'qtree', 'q1' }.to raise_error(Puppet::Error, 'Executing api call qtree-create qtree q1 failed: "Authorization failed"')
    end
  end
end
