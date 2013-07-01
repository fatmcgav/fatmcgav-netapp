require 'spec_helper'
 
describe Puppet::Type.type(:netapp_role) do

  before :each do
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :providerclass do
    described_class.provide(:fake_netapp_role_provider) { mk_resource_methods }
  end

  it "should have :rolename be its namevar" do
    described_class.key_attributes.should == [:rolename]
  end

  describe "when validating attributes" do
    [:rolename, :provider, :comment].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :capabilities].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for rolename" do
      it "should support an alphanumerical name" do
        described_class.new(:rolename => 'role1', :ensure => :present)[:rolename].should == 'role1'
      end

      it "should support underscores" do
        described_class.new(:rolename => 'role_1', :ensure => :present)[:rolename].should == 'role_1'
      end

      it "should support hyphens" do
        described_class.new(:rolename => 'role-1', :ensure => :present)[:rolename].should == 'role-1'
      end

      it "should not support spaces" do
        expect { described_class.new(:rolename => 'role 1', :ensure => :present) }.to raise_error(Puppet::Error, /role 1 is not a valid role name/)
      end
    end

    describe "for ensure" do
      it "should support present" do
        described_class.new(:rolename => 'role1', :ensure => 'present')[:ensure].should == :present
      end

      it "should support absent" do
        described_class.new(:rolename => 'role1', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not support other values" do
        expect { described_class.new(:rolename => 'role1', :ensure => 'foo') }.to raise_error(Puppet::Error, /Invalid value "foo"/)
      end
      
      it "should not have a default value" do
        described_class.new(:rolename => 'role1')[:ensure].should == nil
      end
    end
    
    describe "for comment" do
      it "should support an alphanumerical comment, with hyphens and fullstop" do
        described_class.new(:rolename => 'role1', :comment => 'This is test role-1.', :ensure => :present)[:comment].should == 'This is test role-1.'
      end

      it "should not support special characters" do
        expect { described_class.new(:rolename => 'role1', :comment => 'This is test role !', :ensure => :present) }.to raise_error(Puppet::Error, /This is test role ! is not a valid comment/)
      end
    end
    
    describe "for capabilities" do
      it "should support a single capability" do
        described_class.new(:rolename => 'role', :capabilities => 'login-api')[:capabilities].should == 'login-api'
      end
      
      it "should support a comma-seperated list of capabilities" do
        described_class.new(:rolename => 'role1', :capabilities => 'login-api,login-ssh')[:capabilities].should == 'login-api,login-ssh'
      end
      
      it "should support a wildcard capability" do
        described_class.new(:rolename => 'role1', :capabilities => 'login-*')[:capabilities].should == 'login-*'
      end
      
      it "should not support special characters" do
        expect { described_class.new(:rolename => 'user1', :capabilities => 'login-!') }.to raise_error(Puppet::Error, /login-! is not a valid capabilities list/)
      end
    end
    
  end

end