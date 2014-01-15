#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_igroup_initiator).provider(:netapp_igroup_initiator) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_igroup_initiator).stubs(:defaultprovider).returns described_class
  end

  let :igroup_initiator_create do
    Puppet::Type.type(:netapp_igroup_initiator).new(
    :name                    => 'test_group_initiator',
    :initiator      		 => 'test_user',
    :ensure                  => :present
    )
  end

  let :igroup_initiator_remove do
    Puppet::Type.type(:netapp_igroup_initiator).new(
    :name     	=> 'test_group_initiator',
	:initiator  => 'test_user',
    :ensure     => :absent
    )
  end

  let :provider do
    described_class.new()
  end

  context "when netapp igroup initiator provider is created " do
    it "should have create method defined for netapp igroup initiator" do
      igroup_initiator_create.provider.class.instance_method(:create).should_not == nil
    end

    it "should have destroy method defined for netapp igroup initiator" do
      igroup_initiator_create.provider.class.instance_method(:destroy).should_not == nil
    end

    it "should have exists? method defined for netapp igroup initiator" do
      igroup_initiator_create.provider.class.instance_method(:exists?).should_not == nil
    end

  end

  context "when netapp igroup initiator is created" do
    it "should be able to create a igroup initiator resource" do
      #Then
      igroup_initiator_create.provider.expects(:igroupadd).at_most(3).with('initiator-group-name', 'test_group_initiator', 'initiator', 'test_user')
      igroup_initiator_create.provider.expects(:get_igroup_initiator_status).at_most(2).with().returns('false', 'true')
      igroup_initiator_create.provider.expects(:err).never

      #When
      igroup_initiator_create.provider.create
    end

    it "should not be able to create a igroup initiator resource" do
      #Then	  
      igroup_initiator_create.provider.expects(:igroupadd).at_most(3).with('initiator-group-name', 'test_group_initiator', 'initiator', 'test_user')
      igroup_initiator_create.provider.expects(:get_igroup_initiator_status).at_most(2).with().returns('false','false')
      igroup_initiator_create.provider.expects(:info).never

      #When
      expect {igroup_initiator_create.provider.create}.to raise_error(Puppet::Error)
    end

    context "when netapp igroup initiator is removed" do
      it "should be able remove igroup initiator resource" do
        #Then
        igroup_initiator_remove.provider.expects(:igroupremove).at_most(3).with('initiator-group-name', 'test_group_initiator', 'initiator', 'test_user')
        igroup_initiator_remove.provider.expects(:get_igroup_initiator_status).at_most(2).with().returns('true','false')
        igroup_initiator_remove.provider.expects(:err).never

        #When
        igroup_initiator_remove.provider.destroy
      end

      it "should not be able remove igroup initiator resource" do
        #Then		
        igroup_initiator_remove.provider.expects(:igroupremove).at_most(3).with('initiator-group-name', 'test_group_initiator', 'initiator', 'test_user')
        igroup_initiator_remove.provider.expects(:get_igroup_initiator_status).at_most(2).with().returns('true','true')
        igroup_initiator_remove.provider.expects(:info).never

        #When
        expect {igroup_initiator_remove.provider.destroy}.to raise_error(Puppet::Error)
      end

    end
  end
end