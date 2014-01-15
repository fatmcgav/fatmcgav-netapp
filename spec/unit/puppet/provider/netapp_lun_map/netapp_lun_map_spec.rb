#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_lun_map).provider(:netapp_lun_map) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_lun_map).stubs(:defaultprovider).returns described_class
  end

  let :lun_map do
    Puppet::Type.type(:netapp_lun_map).new(
    :name                    => '/vol/testVolumeFCoE/testLun_test',
    :ensure                  => :present,
    :initiatorgroup          => 'test_group'
    )
  end

  let :lun_unmap do
    Puppet::Type.type(:netapp_lun_map).new(
    :name     => '/vol/testVolumeFCoE/testLun_test',
    :ensure   => :absent,
    :initiatorgroup          => 'test_group'
    )
  end

  let :provider do
    described_class.new()
  end

  context "when netapp lun mapping provider is created " do
    it "should have create method defined for netapp lun map" do
      lun_map.provider.class.instance_method(:create).should_not == nil
    end

    it "should have destroy method defined for netapp lun map" do
      lun_map.provider.class.instance_method(:destroy).should_not == nil
    end

    it "should have exists? method defined for netapp lun map" do
      lun_map.provider.class.instance_method(:exists?).should_not == nil
    end

  end

  context "when mapping a lun resource" do
    it "should be able to map a lun resource" do
      #Then
      lun_map.provider.expects(:lunmap).at_most(3).with('path', '/vol/testVolumeFCoE/testLun_test', 'initiator-group','test_group')
      lun_map.provider.expects(:get_lun_mapped_status).at_most(2).with().returns('false','true')
      lun_map.provider.expects(:err).never

      #When
      lun_map.provider.create
    end

    it "should not be able to map a lun resource" do
      #Then
	 
      lun_map.provider.expects(:lunmap).at_most(3).with('path', '/vol/testVolumeFCoE/testLun_test', 'initiator-group','test_group')
      lun_map.provider.expects(:get_lun_mapped_status).at_most(2).with().returns('false','false')
      lun_map.provider.expects(:info).never

      #When
       expect {lun_map.provider.create}.to raise_error(Puppet::Error)
    end

    context "when removing mapping of a lun resource" do
      it "should be able to un-map a lun resource" do
        #Then
        lun_unmap.provider.expects(:lununmap).at_most(3).with('path', '/vol/testVolumeFCoE/testLun_test', 'initiator-group','test_group')
        lun_unmap.provider.expects(:get_lun_mapped_status).at_most(2).with().returns('true','false')
        lun_unmap.provider.expects(:err).never

        #When
        lun_unmap.provider.destroy
      end

      it "should not be able to un-map a lun resource" do
        #Then
		
        lun_unmap.provider.expects(:lununmap).at_most(3).with('path', '/vol/testVolumeFCoE/testLun_test', 'initiator-group','test_group')
        lun_unmap.provider.expects(:get_lun_mapped_status).at_most(2).with().returns('true','true')
        lun_unmap.provider.expects(:info).never

        #When
        expect {lun_unmap.provider.destroy}.to raise_error(Puppet::Error)
		
      end

    end
  end
end