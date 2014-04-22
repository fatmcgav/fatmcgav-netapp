require 'spec_helper'
 
describe Puppet::Type.type(:netapp_group) do

  before do 
    @group_example = {
      :groupname => 'group',  
      :comment   => 'Group comment', 
      :roles     => 'roles'
    }
    @provider = stub('provider', :class => described_class.defaultprovider, :clear => nil)
    described_class.defaultprovider.stubs(:new).returns(@provider)
  end

  let :group_resource do 
    @group_example
  end

  it "should have :groupname be its namevar" do
    described_class.key_attributes.should == [:groupname]
  end

  describe "when validating attributes" do
    [:groupname, :provider, :comment].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :roles].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for groupname" do
      it "should support an alphanumerical name" do
        described_class.new(:groupname => 'group1', :ensure => :present)[:groupname].should == 'group1'
      end

      it "should support underscores" do
        described_class.new(:groupname => 'group_1', :ensure => :present)[:groupname].should == 'group_1'
      end

      it "should support hyphens" do
        described_class.new(:groupname => 'group-1', :ensure => :present)[:groupname].should == 'group-1'
      end

      it "should not support spaces" do
        expect { described_class.new(:groupname => 'group 1', :ensure => :present) }.to raise_error(Puppet::Error, /group 1 is not a valid group name/)
      end
    end

    describe "for ensure" do
      it "should support present" do
        described_class.new(:groupname => 'group1', :ensure => 'present')[:ensure].should == :present
      end

      it "should support absent" do
        described_class.new(:groupname => 'group1', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not support other values" do
        expect { described_class.new(:groupname => 'group1', :ensure => 'foo') }.to raise_error(Puppet::Error, /Invalid value "foo"/)
      end
      
      it "should not have a default value" do
        described_class.new(:groupname => 'group1')[:ensure].should == nil
      end
    end
    
    describe "for comment" do
      it "should support an alphanumerical comment, with hyphens and fullstop" do
        described_class.new(:groupname => 'group1', :comment => 'This is test group-1.', :ensure => :present)[:comment].should == 'This is test group-1.'
      end

      it "should not support special characters" do
        expect { described_class.new(:groupname => 'group1', :comment => 'This is test group !', :ensure => :present) }.to raise_error(Puppet::Error, /This is test group ! is not a valid comment/)
      end
    end
    
    describe "for roles" do
      it "should support a single role" do
        described_class.new(:groupname => 'group1', :roles => 'role1')[:roles].should == 'role1'
      end
      
      it "should support a comma-seperated list of role names" do
        described_class.new(:groupname => 'group1', :roles => 'role1,role2')[:roles].should == 'role1,role2'
      end
      
      it "should not support special characters" do
        expect { described_class.new(:groupname => 'user1', :roles => 'role!') }.to raise_error(Puppet::Error, /role! is not a valid role list/)
      end
      
      it "insync? should return false if is and should values dont match" do
        group = group_resource.dup
        is_roles = 'role1'
        group[:roles] = 'role1,role2'
        described_class.new(group).property(:roles).insync?(is_roles).should be_false
      end
      
      it "insync? should return true if is and should values match" do
        group = group_resource.dup
        is_roles = 'role1,role2'
        group[:roles] = 'role1,role2'
        described_class.new(group).property(:roles).insync?(is_roles).should be_true
      end
    end
    
  end
  
  describe "autorequiring" do
    let :group do
      described_class.new(
        :groupname => 'group1',
        :ensure    => :present,
        :roles     => 'puppetrole'
      )
    end

    let :roleprovider do
      Puppet::Type.type(:netapp_role).provide(:fake_netapp_role_provider) { mk_resource_methods }
    end

    let :role do
      Puppet::Type.type(:netapp_role).new(
        :rolename => 'puppetrole',
        :ensure   => :present
      )
    end

    let :catalog do
      Puppet::Resource::Catalog.new
    end

    before :each do
      Puppet::Type.type(:netapp_role).stubs(:defaultprovider).returns roleprovider
    end

    it "should not autorequire a role when no matching role can be found" do
      catalog.add_resource group
      group.autorequire.should be_empty
    end

    it "should autorequire a matching role" do
      catalog.add_resource group
      catalog.add_resource role
      reqs = group.autorequire
      reqs.size.should == 1
      reqs[0].source.must == role
      reqs[0].target.must == group
    end
  end
end