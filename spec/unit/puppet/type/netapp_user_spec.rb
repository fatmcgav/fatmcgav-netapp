require 'spec_helper'
 
describe Puppet::Type.type(:netapp_user) do

  before do 
    @user_example = {
      :username => 'user', 
      :password => 'password',
      :fullname => 'User Name', 
      :comment  => 'User comment', 
      #:passminage => '0', 
      #:passmaxage => '',
      :groups   => 'group'
    }
    @provider = stub('provider', :class => described_class.defaultprovider, :clear => nil)
    described_class.defaultprovider.stubs(:new).returns(@provider)
  end

  let :user_resource do 
    @user_example
  end

  it "should have :username be its namevar" do
    described_class.key_attributes.should == [:username]
  end

  describe "when validating attributes" do
    [:username, :provider, :password, :status].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :fullname, :comment, :passminage, :passmaxage, :groups].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for username" do
      it "should support an alphanumerical name" do
        described_class.new(:username => 'user1', :ensure => :present)[:username].should == 'user1'
      end

      it "should support underscores" do
        described_class.new(:username => 'foo_bar', :ensure => :present)[:username].should == 'foo_bar'
      end

      it "should support hyphens" do
        described_class.new(:username => 'abc-def', :ensure => :present)[:username].should == 'abc-def'
      end

      it "should not support spaces" do
        expect { described_class.new(:username => 'user 1', :ensure => :present) }.to raise_error(Puppet::Error, /user 1 is not a valid username/)
      end
    end

    describe "for ensure" do
      it "should support present" do
        described_class.new(:username => 'user1', :ensure => 'present')[:ensure].should == :present
      end

      it "should support absent" do
        described_class.new(:username => 'user1', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not support other values" do
        expect { described_class.new(:username => 'user1', :ensure => 'foo') }.to raise_error(Puppet::Error, /Invalid value "foo"/)
      end
      
      it "should not have a default value" do
        described_class.new(:username => 'user1')[:ensure].should == nil
      end
    end

    describe "for password" do
      it "should support an alphanumeric password" do
        described_class.new(:username => 'user1', :password => 'abcd1234', :ensure => :present)[:password].should == 'abcd1234'
      end

      it "should not support spaces" do
        expect { described_class.new(:username => 'user1', :password => 'abd 123', :ensure => :present) }.to raise_error(Puppet::Error, /abd 123 is not a valid password/)
      end
      
      it "should be a minimum of 8 characters" do
        expect { described_class.new(:username => 'user1', :password => 'abc123', :ensure => :present) }.to raise_error(Puppet::Error, /abc123 is not a valid password/)
      end
    end
    
    describe "for fullname" do
      it "should support a forename and surname with a space" do
        described_class.new(:username => 'user1', :fullname => 'user test', :ensure => :present)[:fullname].should == 'user test'
      end

      it "should not support special characters" do
        expect { described_class.new(:username => 'user1', :fullname => 'user !', :ensure => :present) }.to raise_error(Puppet::Error, /user ! is not a valid full name/)
      end
    end
    
    describe "for comment" do
      it "should support an alphanumerical comment, with hyphens and fullstop" do
        described_class.new(:username => 'user-1', :comment => 'This is test user-1.', :ensure => :present)[:comment].should == 'This is test user-1.'
      end

      it "should not support special characters" do
        expect { described_class.new(:username => 'user1', :comment => 'This is test user !', :ensure => :present) }.to raise_error(Puppet::Error, /This is test user ! is not a valid comment/)
      end
    end
    
    describe "for passminage" do
      it "should support a numerical value" do
        described_class.new(:username => 'user1', :passminage => '10', :ensure => :present)[:passminage].should == 10
      end

      it "should support a minimum value of 0" do
        described_class.new(:username => 'user1', :passminage => '0', :ensure => :present)[:passminage].should == 0
      end
      
      it "should support a maximum value of 4294967295" do
        described_class.new(:username => 'user1', :passminage => '4294967295', :ensure => :present)[:passminage].should == 4294967295
      end
      
      it "should have a default value of 0" do
        described_class.new(:username => 'user1', :ensure => :present)[:passminage].should == 0
      end
      
      it "should not support a value larger than 4294967295" do
        expect { described_class.new(:username => 'user1', :passminage => '4294967296', :ensure => :present) }.to raise_error(Puppet::Error, /Passminage must be between 0 and 4294967295./)
      end
      
      it "should not support a non-numeric value" do
        expect { described_class.new(:username => 'user1', :passminage => 'a', :ensure => :present) }.to raise_error(Puppet::Error, /a is not a valid password minimum age./)
      end
    end
    
    describe "for passmaxage" do
      it "should support a numerical value" do
        described_class.new(:username => 'user1', :passmaxage => '10', :ensure => :present)[:passmaxage].should == 10
      end

      it "should support a minimum value of 0" do
        described_class.new(:username => 'user1', :passmaxage => '0', :ensure => :present)[:passmaxage].should == 0
      end
      
      it "should support a maximum value of 4294967295" do
        described_class.new(:username => 'user1', :passmaxage => '4294967295', :ensure => :present)[:passmaxage].should == 4294967295
      end
      
      it "should have a default value of 4294967295" do
        described_class.new(:username => 'user1', :ensure => :present)[:passmaxage].should == 4294967295
      end
      
      it "should not support a value larger than 4294967295" do
        expect { described_class.new(:username => 'user1', :passmaxage => '4294967296', :ensure => :present) }.to raise_error(Puppet::Error, /Passmaxage must be between 0 and 4294967295./)
      end
      
      it "should not support a non-numeric value" do
        expect { described_class.new(:username => 'user1', :passmaxage => 'a', :ensure => :present) }.to raise_error(Puppet::Error, /a is not a valid password maximum age./)
      end
    end
    
    describe "for status" do
      it "should support enabled" do
        described_class.new(:username => 'user1', :status => 'enabled')[:status].should == :enabled
      end

      it "should support disabled" do
        described_class.new(:username => 'user1', :status => 'disabled')[:status].should == :disabled
      end

      it "should support expired" do
        described_class.new(:username => 'user1', :status => 'expired')[:status].should == :expired
      end
      
      it "should have a default value of enabled" do
        described_class.new(:username => 'user1')[:status].should == :enabled
      end
      
      it "should not support other values" do
        expect { described_class.new(:username => 'user1', :status => 'foo') }.to raise_error(Puppet::Error, /Invalid value "foo"/)
      end
    end
    
    describe "for groups" do
      it "should support a single group" do
        described_class.new(:username => 'user1', :groups => 'group1')[:groups].should == 'group1'
      end
      
      it "should support a comma-seperated list of group names" do
        described_class.new(:username => 'user1', :groups => 'group1,group2')[:groups].should == 'group1,group2'
      end
      
      it "should not support special characters" do
        expect { described_class.new(:username => 'user1', :groups => 'group!') }.to raise_error(Puppet::Error, /group! is not a valid group list/)
      end
      
      it "insync? should return false if is and should values dont match" do
        user = user_resource.dup
        is_groups = 'group1'
        user[:groups] = 'group1,group2'
        described_class.new(user).property(:groups).insync?(is_groups).should be_false
      end
      
      it "insync? should return true if is and should values match" do
        user = user_resource.dup
        is_groups = 'group1,group2'
        user[:groups] = 'group1,group2'
        described_class.new(user).property(:groups).insync?(is_groups).should be_true
      end
    end

  end
  
  describe "autorequiring" do
    let :user do
      described_class.new(
        :username => 'user1',
        :ensure   => :present,
        :groups   => 'puppetgroup,Users,Power Users'
      )
    end

    let :groupprovider do
      Puppet::Type.type(:netapp_group).provide(:fake_netapp_group_provider) { mk_resource_methods }
    end

    let :group do
      Puppet::Type.type(:netapp_group).new(
        :groupname => 'puppetgroup',
        :ensure    => :present,
        :roles     => 'power'
      )
    end

    let :catalog do
      Puppet::Resource::Catalog.new
    end

    before :each do
      Puppet::Type.type(:netapp_group).stubs(:defaultprovider).returns groupprovider
    end

    it "should not autorequire a group when no matching group can be found" do
      catalog.add_resource user
      user.autorequire.should be_empty
    end

    it "should autorequire a matching group" do
      catalog.add_resource user
      catalog.add_resource group
      reqs = user.autorequire
      reqs.size.should == 1
      reqs[0].source.must == group
      reqs[0].target.must == user
    end
  end
end