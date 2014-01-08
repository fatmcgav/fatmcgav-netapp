#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:netapp_lun_clone) do 
  
  let :resource do
    described_class.new(
                :name  			=> '/vol/testVolume/testLun2',
		:ensure			=> :present,
		:parentlunpath 		=> '/vol/testVolume/testLun1',
		:parentsnap		=> 'snap1',
		:spacereservationenabled => :true
    )
  end

  
 it "should have name as its keyattribute" do
    described_class.key_attributes.should == [:name]
  end

  
  describe "when validating attributes" do
    [:name].each do |param|
      it "should hava a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end
  end

  
  describe "when validating values" do
  
    describe "for name" do
      it "should allow a valid mapping name where ensure is present" do
        described_class.new(:name => '/vol/testVolume/testLun2', :ensure => 'present')[:name].should == '/vol/testVolume/testLun2'
      end

      it "should allow a valid mapping name where ensure is absent" do
        described_class.new(:name => '/vol/testVolume/testLun2', :ensure => 'absent')[:name].should == '/vol/testVolume/testLun2'
      end
    end

    describe "for ensure" do
      it "should allow present" do
        described_class.new(:name => '/vol/testVolume/testLun2', :ensure => 'present')[:ensure].should == :present
      end

      it "should allow absent" do
        described_class.new(:name => '/vol/testVolume/testLun2', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'newvolThree', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end
	
  end	
end