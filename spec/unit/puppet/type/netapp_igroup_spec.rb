#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:netapp_igroup) do

  let :resource do
    described_class.new(
    :name          	     => 'Test_iGroup_Test',
    :ensure        	     => 'present',
    :initiatorgrouptype	 => 'initiatorgrouptype',
    :ostype		           => 'ostype'
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
        described_class.new(:name => 'Test_iGroup_Test', :ensure => 'present')[:name].should == 'Test_iGroup_Test'
      end

      it "should allow a valid mapping name where ensure is absent" do
        described_class.new(:name => 'Test_iGroup_Test', :ensure => 'absent')[:name].should == 'Test_iGroup_Test'
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'Test_iGroup_Test_1', :ensure => 'present') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for ensure" do
      it "should allow present" do
        described_class.new(:name => 'Test_iGroup_Test', :ensure => 'present')[:ensure].should == :present
      end

      it "should allow absent" do
        described_class.new(:name => 'Test_iGroup_Test', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'Test_iGroup_Test', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for initiatorgrouptype" do
      it "should allow a valid initiatorgrouptype" do
        described_class.new(:name => 'Test_iGroup_Test', :initiatorgrouptype => 'initiatorgrouptype')[:initiatorgrouptype].should == 'initiatorgrouptype'
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'Test_iGroup_Test', :initiatorgrouptype => 'abc') }.to raise_error Puppet::Error, /Invalid value/
      end

    end

    describe "for ostype" do
      it "should allow a valid ostype" do
        described_class.new(:name => 'Test_iGroup_Test', :ostype => 'ostype')[:ostype].should == 'ostype'
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'Test_iGroup_Test', :ostype => 'abc') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

  end

end
