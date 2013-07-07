#! /usr/bin/env ruby

require 'spec_helper'
require 'puppet/util/network_device/netapp/device'
require 'yaml'

describe Puppet::Util::NetworkDevice::Netapp::Device do

  let :version do
    YAML.load_file(my_fixture('system-get-version.yml'))
  end

  describe "when connecting to a new device" do
    it "should reject a single hostname" do
      expect { described_class.new('pfiler.example.com') }.to raise_error ArgumentError, /Invalid scheme/
    end

    it "should reject a missing username" do
      expect { described_class.new('https://pfiler.example.com') }.to raise_error ArgumentError, 'no user specified'
    end

    it "should reject a missing password" do
      expect { described_class.new('https://root@pfiler.example.com') }.to raise_error ArgumentError, 'no password specified'
    end

    it "should not accept plain http connections" do
      expect { described_class.new('http://root:secret@pfiler.example.com') }.to raise_error ArgumentError, 'Invalid scheme http. Must be https'
    end

    it "should connect to the specified filer" do
      transport = mock 'netapp server'
      Puppet.expects(:debug).with regexp_matches %r{connecting to Netapp device https://root:\*\*\*\*@pfiler\.example\.com}
      NaServer.expects(:new).with('pfiler.example.com', 1, 13).returns transport
      transport.expects(:set_admin_user).with('root', 'secret')
      transport.expects(:set_transport_type).with('HTTPS')
      transport.expects(:set_port).with(443)
      transport.expects(:invoke).with('system-get-version').returns version
      Puppet.expects(:debug).with regexp_matches /^Puppet::Device::Netapp: Version = /

      described_class.new('https://root:secret@pfiler.example.com')
    end

    it "should support vfiler" do
      transport = mock 'netapp server'
      NaServer.expects(:new).with('pfiler.example.com', 1, 13).returns transport
      Puppet.expects(:debug).with regexp_matches %r{connecting to Netapp device https://root:\*\*\*\*@pfiler\.example\.com}
      Puppet.expects(:debug).with regexp_matches /^Puppet::Device::Netapp: Version = /
      Puppet.expects(:debug).with 'Puppet::Device::Netapp: vfiler context has been set to VFILER01'
      transport.expects(:set_admin_user).with('root', 'secret')
      transport.expects(:set_transport_type).with('HTTPS')
      transport.expects(:set_port).with(443)
      transport.expects(:set_vfiler).with('VFILER01')
      transport.expects(:invoke).with('system-get-version').returns version

      described_class.new('https://root:secret@pfiler.example.com/VFILER01/reserved_for_later_usage')
    end
  end
end
