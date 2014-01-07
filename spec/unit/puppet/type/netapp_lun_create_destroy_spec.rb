#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:netapp_lun_create_destroy) do 
  
  let :resource do
    described_class.new(
        :name  				=> '/vol/testVolume/testLun1',
		:ensure				=> :present,
		:size_bytes 		=> '20000000',
		:ostype				=> 'vmware',
		:space_res_enabled 	=> :true
    )
  end

  
  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [:name]
  end

  
  describe "when validating attributes" do
    [:name,:size_bytes,:ostype].each do |param|
      it "should hava a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end
  end

  
  describe "when validating values" do
  
    describe "for name" do
      it "should allow a valid Lun name" do
        resource.name.should eq( '/vol/testVolume/testLun1')
      end      
    end

    describe "for ensure" do
      it "should allow present" do
        described_class.new(:name => resource.name, :ensure => 'present')[:ensure].should == :present
      end
	  
	  it "should allow present" do
        expect { described_class.new(:name => resource.name, :ensure => 'invalid') }.to raise_error Puppet::Error, /Invalid value/
      end
    
    end
	
	 describe "for size bytes" do
      it "should allow a valid size bytes" do
	   described_class.new(:name => resource.name,:size_bytes => '20000000')[:size_bytes].should == '20000000'
      end    
    end
	
	 describe "for ostype" do
      it "should allow a valid ostype" do
         described_class.new(:name => resource.name,:ostype => 'vmware')[:ostype].should == 'vmware'
      end    
    end
	
	describe "for space res enabled" do
      it "should allow a valid space res enabled" do
      described_class.new(:name => resource.name,:space_res_enabled => true)[:space_res_enabled].should == :true
      end    
    end
	
  end	
end