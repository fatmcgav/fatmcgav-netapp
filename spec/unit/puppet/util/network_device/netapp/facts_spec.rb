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

  let :facts do
    described_class.new(transport)
  end

  before :each do
    transport.expects(:invoke).with('system-get-version').returns version
    transport.expects(:invoke).with('system-get-info').returns info
    transport.expects(:invoke).with('options-get', 'name', 'dns.domainname').returns domainname
  end

  describe "#retrieve" do
    it "should mixin the version from system-get-version" do
      facts.retrieve["version"].should == "NetApp Release 8.1P2 7-Mode: Tue Jun 12 17:53:00 PDT 2012 Multistore"
    end

    it "should mixin the domainname from options-get" do
      facts.retrieve["domain"].should == 'example.com'
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
        facts.retrieve[fact.to_s].should == expected_value
      end
    end
  end
end
