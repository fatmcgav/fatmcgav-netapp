#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_igroup).provider(:netapp_igroup) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_igroup).stubs(:defaultprovider).returns described_class
  end

  let :igroup_create do
    Puppet::Type.type(:netapp_igroup).new(
    :name                    => 'test_group',
    :ensure                  => :present,
    :initiatorgrouptype      => 'fcp'
    )
  end

  let :igroup_remove do
    Puppet::Type.type(:netapp_igroup).new(
    :name     => 'test_group',
    :ensure   => :absent
    )
  end

  let :provider do
    described_class.new()
  end

  context "when netapp igroup provider is created " do
    it "should have create method defined for netapp igroup" do
      igroup_create.provider.class.instance_method(:create).should_not == nil
    end

    it "should have destroy method defined for netapp igroup" do
      igroup_create.provider.class.instance_method(:destroy).should_not == nil
    end

    it "should have exists? method defined for netapp igroup" do
      igroup_create.provider.class.instance_method(:exists?).should_not == nil
    end

  end

  context "when netapp igroup is created" do
    it "should be able to create a igroup resource" do
      #Then
      igroup_create.provider.expects(:igroupcreate).at_most(3).with('initiator-group-name', 'test_group', 'initiator-group-type', 'fcp')
      igroup_create.provider.expects(:get_igroup_status).at_most(2).with().returns('false', 'true')
      igroup_create.provider.expects(:err).never

      #When
      igroup_create.provider.create
    end

    it "should not be able to create a igroup resource" do
      #Then	  
      igroup_create.provider.expects(:igroupcreate).at_most(3).with('initiator-group-name', 'test_group', 'initiator-group-type', 'fcp')
      igroup_create.provider.expects(:get_igroup_status).at_most(2).with().returns('false','false')
      igroup_create.provider.expects(:info).never

      #When
      expect {igroup_create.provider.create}.to raise_error(Puppet::Error)
    end

    context "when netapp igroup is removed" do
      it "should be able remove igroup resource" do
        #Then
        igroup_remove.provider.expects(:igroupdestroy).at_most(3).with('initiator-group-name', 'test_group')
        igroup_remove.provider.expects(:get_igroup_status).at_most(2).with().returns('true','false')
        igroup_remove.provider.expects(:err).never

        #When
        igroup_remove.provider.destroy
      end

      it "should not be able remove igroup resource" do
        #Then		
        igroup_remove.provider.expects(:igroupdestroy).at_most(3).with('initiator-group-name', 'test_group')
        igroup_remove.provider.expects(:get_igroup_status).at_most(2).with().returns('true','true')
        igroup_remove.provider.expects(:info).never

        #When
        expect {igroup_remove.provider.destroy}.to raise_error(Puppet::Error)
      end

    end
  end
end