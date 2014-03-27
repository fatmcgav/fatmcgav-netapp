#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device'
require 'puppet/util/network_device/netapp/device'

describe Puppet::Util::NetworkDevice::Netapp::Facts do

  let :transport do
    mock 'netapp server'
  end

  let :version do
    YAML.load_file(my_fixture('system-get-version.yml'))
  end

  let :info do
    YAML.load_file(my_fixture('system-get-info.yml'))
  end

  let :domainname do
    YAML.load_file(my_fixture('options-get-dns.domainname.yml'))
  end

  let :network do
    YAML.load_file(my_fixture('network-iface-get.yml'))
  end

  let :result_failed do
    n = NaElement.new("results")
    n.attr_set("status", "failed")
    n.attr_set("reason", "No response received")
    n.attr_set("errno", 13001)
    n
  end

  let :facts do
    described_class.new(transport).retrieve
  end

  before :each do
    transport.expects(:invoke).with('system-get-version').returns version
    transport.expects(:invoke).with('system-get-info').returns info
    transport.expects(:invoke).with('options-get', 'name', 'dns.domainname').returns domainname
  end

  describe "#retrieve" do
    it "should mixin the version from system-get-version" do
      transport.expects(:invoke).with('net-ifconfig-get').returns network
      facts["version"].should == "NetApp Release 8.1P2 7-Mode: Tue Jun 12 17:53:00 PDT 2012 Multistore"
    end

    it "should mixin the domainname from options-get" do
      transport.expects(:invoke).with('net-ifconfig-get').returns network
      facts["domain"].should == 'example.com'
    end

    it "should not gather interface facts if net-ifconfig-get is not supported" do
      transport.expects(:invoke).with('net-ifconfig-get').returns result_failed
      Puppet.expects(:debug).with('API call net-ifconfig-get failed. Probably not supported. Not gathering interface facts')
      facts
    end


    it "should create an \"ipaddress\" fact for each interfaces if net-ifconfig-get is supported" do
      transport.expects(:invoke).with('net-ifconfig-get').returns network
      facts['ipaddress_e0a'].should == '192.168.150.119'
      facts.should_not have_key 'ipaddress_e0b'
      facts.should_not have_key 'ipaddress_e0c'
      facts.should_not have_key 'ipaddress_e0d'
    end

    it "should create a \"netmask\" fact for each interfaces if net-ifconfig-get is supported" do
      transport.expects(:invoke).with('net-ifconfig-get').returns network
      facts['netmask_e0a'].should == '255.255.254.0'
      facts.should_not have_key 'netmask_e0b'
      facts.should_not have_key 'netmask_e0c'
      facts.should_not have_key 'netmask_e0d'
    end

    it "should create a \"macaddress\" fact for each interface if net-ifconfig-get is supported" do
      transport.expects(:invoke).with('net-ifconfig-get').returns network
      facts["macaddress_e0a"].should == '00:0c:29:77:e8:78'
      facts["macaddress_e0b"].should == '00:0c:29:77:e8:82'
      facts["macaddress_e0c"].should == '00:0c:29:77:e8:8c'
      facts["macaddress_e0d"].should == '00:0c:29:77:e8:96'
    end

    it "should create an \"interfaces\" fact as a comma separated list of interfaces" do
      transport.expects(:invoke).with('net-ifconfig-get').returns network
      facts["interfaces"].should == 'e0a,e0b,e0c,e0d'
    end

    {
      :productname            => 'FAS3240',
      :manufacturer           => 'NetApp',
      :operatingsystem        => 'OnTAP',
      :operatingsystemrelease => '8.1P2',
      :hostname               => 'filer01',
      :fqdn                   => 'filer01.example.com',
      :uniqueid               => '1918293798',
      :serialnumber           => '123289979812',
      :processorcount         => '4',
      :memorysize_mb          => '8192',
      :memorysize             => '8192 MB',
      :hardwareisa            => 'Intel(R) Xeon(R) CPU           L5410  @ 2.33GHz',
      :is_clustered           => 'false',
    }.each do |fact, expected_value|
      it "should return #{expected_value} for #{fact}" do
        transport.expects(:invoke).with('net-ifconfig-get').returns network
        facts[fact.to_s].should == expected_value
      end
    end
  end
end
