#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:netapp_lun_clone).provider(:netapp_lun_clone) do

  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_lun_clone).stubs(:defaultprovider).returns described_class
  end

  let :lun_clone do
    Puppet::Type.type(:netapp_lun_clone).new(
    :name                    => '/vol/testVolumeFCoE/testLun_test',
    :ensure                  => :present,
    :parentlunpath           => '/vol/testVolume/testLun1',
    :parentsnap              => 'test_snap'
    )
  end

  let :lun_delete do
    Puppet::Type.type(:netapp_lun_clone).new(
    :name     => '/vol/testVolumeFCoE/testLun_test',
    :ensure   => :absent
    )
  end

  let :provider do
    described_class.new()
  end

  context "when netapp lun clone provider is created " do
    it "should have create method defined for netapp lun clone" do
      lun_clone.provider.class.instance_method(:create).should_not == nil
    end

    it "should have destroy method defined for netapp lun clone" do
      lun_clone.provider.class.instance_method(:destroy).should_not == nil
    end

    it "should have exists? method defined for netapp lun clone" do
      lun_clone.provider.class.instance_method(:exists?).should_not == nil
    end

  end

  context "when cloning a lun resource" do
    it "should be able to clone a lun resource" do
      #Then
      lun_clone.provider.expects(:luncreateclone).with('parent-lun-path', '/vol/testVolume/testLun1', 'path', '/vol/testVolumeFCoE/testLun_test', 'parent-snap','test_snap')
      lun_clone.provider.expects(:get_lun_existence_status).with().returns 'true'
      lun_clone.provider.expects(:err).never

      #When
      lun_clone.provider.create
    end

    it "should not be able to clone a lun resource" do
      #Then
      lun_clone.provider.expects(:luncreateclone).with('parent-lun-path', '/vol/testVolume/testLun1', 'path', '/vol/testVolumeFCoE/testLun_test', 'parent-snap','test_snap').returns ""
      lun_clone.provider.expects(:get_lun_existence_status).with().returns 'false'
      lun_clone.provider.expects(:info).never

      #When
      expect {lun_clone.provider.create}.to raise_error(Puppet::Error)
    end

    context "when deleting a lun resource" do
      it "should be able to delete a lun resource" do
        #Then
        lun_delete.provider.expects(:lundestroy).with('path', '/vol/testVolumeFCoE/testLun_test').returns ""
        lun_delete.provider.expects(:get_lun_existence_status).with().returns 'false'
        lun_delete.provider.expects(:err).never

        #When
        lun_delete.provider.destroy
      end

      it "should not be able to delete a lun resource" do
        #Then
        lun_delete.provider.expects(:lundestroy).with('path', '/vol/testVolumeFCoE/testLun_test').returns ""
        lun_delete.provider.expects(:get_lun_existence_status).with().returns 'true'
        lun_delete.provider.expects(:info).never

        #When
        expect {lun_delete.provider.destroy}.to raise_error(Puppet::Error)
      end

    end
  end
end