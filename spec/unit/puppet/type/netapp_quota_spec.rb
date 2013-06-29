#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:netapp_quota) do

  let :resource do
    described_class.new(
      :name          => '/vol/vol0/q1',
      :ensure        => :present,
      :volume        => 'vol0',
      :disklimit     => '100G',
      :softdisklimit => '50G',
      :filelimit     => '4096',
      :softfilelimit => '2048',
      :threshold     => '50G'
    )
  end

  it "should have name as its keyattribute" do
    described_class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:name, :provider].each do |param|
      it "should hava a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :disklimit, :softdisklimit, :filelimit, :softfilelimit, :qtree, :type, :threshold, :volume].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for name" do
      it "should allow a unix username" do
        described_class.new(:name => 'bob', :type => :user)[:name].should == 'bob'
      end

      it "should allow a windows domain username" do
        described_class.new(:name => 'CORP\bob', :type => :user)[:name].should == 'CORP\bob'
      end

      it "should allow a group" do
        described_class.new(:name => 'staff', :type => :group)[:name].should == 'staff'
      end

      it "should allow a path" do
        described_class.new(:name => '/vol/vol1/q1', :type => :tree)[:name].should == '/vol/vol1/q1'
      end
    end

    describe "for ensure" do
      it "should allow present" do
        described_class.new(:name => 'bob', :ensure => 'present')[:ensure].should == :present
      end

      it "should allow absent" do
        described_class.new(:name => 'bob', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'bob', :ensure => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for type" do
      it "should allow tree" do
        described_class.new(:name => '/vol/vol1/q1', :type => 'tree')[:type].should == :tree
      end

      it "should allow user" do
        described_class.new(:name => 'bob', :type => 'user')[:type].should == :user
      end

      it "should allow group" do
        described_class.new(:name => 'staff', :type => 'group')[:type].should == :group
      end

      it "should not allow something else" do
        expect { described_class.new(:name => 'staff', :type => 'foo') }.to raise_error Puppet::Error, /Invalid value/
      end
    end

    describe "for qtree" do
      it "should allow a qtree name for a user quota" do
        described_class.new(:name => 'bob', :type => :user, :qtree => 'q01')[:qtree].should == 'q01'
      end

      it "should allow a qtree name for a group quota" do
        described_class.new(:name => 'staff', :type => :group, :qtree => 'q01')[:qtree].should == 'q01'
      end

      it "should allow no value for tree type quotas" do
        expect { described_class.new(:name => '/vol/vol1/q1', :type => :tree, :qtree => 'q1') }.to raise_error Puppet::Error, /qtree is invalid for tree type quotas/
      end
    end

    [:disklimit, :softdisklimit, :threshold].each do |size_property|
      describe "for #{size_property}" do
        it "should allow absent make sure the limit is disabled" do
          described_class.new(:name => 'bob', :type => :user, size_property => 'absent')[size_property].should == :absent
        end
        it "should allow and convert a value specified in KiB (unit=K)" do
          described_class.new(:name => 'bob', :type => :user, size_property => '1024K')[size_property].should == 1024*1024
        end

        it "should allow and convert a value specified in MiB (unit=M)" do
          described_class.new(:name => 'bob', :type => :user, size_property => '120M')[size_property].should == 120*1024*1024
        end

        it "should allow and convert a value specified in GiB (unit=G)" do
          described_class.new(:name => 'bob', :type => :user, size_property => '20G')[size_property].should == 20*1024*1024*1024
        end

        it "should not allow negative values" do
          expect { described_class.new(:name => 'bob', :type => :user, size_property => '-20G') }.to raise_error Puppet::Error, /Invalid value/
        end

        it "should not allow non numeric values" do
          expect { described_class.new(:name => 'bob', :type => :user, size_property => 'GGG') }.to raise_error Puppet::Error, /Invalid value/
        end
      end
    end

    [:filelimit, :softfilelimit].each do |numeric_property|
      describe "for #{numeric_property}" do
        it "should allow absent to disable the limit" do
          described_class.new(:name => 'bob', :type => :user, numeric_property => 'absent')[numeric_property].should == :absent
        end

        it "should allow a positive value" do
          described_class.new(:name => 'bob', :type => :user, numeric_property => '4000000000')[numeric_property].should == 4000000000
        end

        it "should allow the unit K" do
          described_class.new(:name => 'bob', :type => :user, numeric_property => '4K')[numeric_property].should == 4096
        end

        it "should allow the unit M" do
          described_class.new(:name => 'bob', :type => :user, numeric_property => '30M')[numeric_property].should == 31457280
        end

        it "should allow the unit G" do
          described_class.new(:name => 'bob', :type => :user, numeric_property => '2G')[numeric_property].should == 2147483648
        end

        it "should allow the unit T" do
          described_class.new(:name => 'bob', :type => :user, numeric_property => '1T')[numeric_property].should == 1099511627776
        end

        it "should not allow a negative value" do
          expect { described_class.new(:name => 'bob', :type => :user, numeric_property => '-300') }.to raise_error Puppet::Error, /Invalid value/
        end

        it "should not allow non numeric values" do
          expect { described_class.new(:name => 'bob', :type => :user, numeric_property => '30a') }.to raise_error Puppet::Error, /Invalid value/
        end
      end
    end

    describe "for volume" do
      it "should allow a simple volume name" do
        described_class.new(:name => 'bob', :type => :user, :volume => 'vol1')[:volume].should == 'vol1'
      end

      it "should allow underscores" do
        described_class.new(:name => 'bob', :type => :user, :volume => 'VFILER01_vol01')[:volume].should == 'VFILER01_vol01'
      end

      it "should not allow slashes" do
        expect { described_class.new(:name => 'bob', :type => :user, :volume => '/vol/vol01') }.to raise_error Puppet::Error, /Invalid value/
      end
    end
  end

  describe "when displaying the current value" do
    [:disklimit, :softdisklimit, :filelimit, :softfilelimit, :threshold].each do |limit_property|
      describe "of #{limit_property} property" do
        let :property do
          resource.property(limit_property)
        end

        it "should display absent as absent" do
          property.is_to_s(:absent).should == :absent
        end

        it "should display no unit if below 1K" do
          property.is_to_s(100).should == "100"
        end

        it "should display 1000 as 1000" do
          property.is_to_s(1000).should == "1000"
        end

        it "should display 1024 as 1K" do
          property.is_to_s(1024).should == "1K"
        end

        it "should display 1025 as 1025" do
          property.is_to_s(1025).should == "1025"
        end

        it "should display 10485760 as 10M" do
          property.is_to_s(10485760).should == "10M"
        end

        it "should display 10484736 as 10239K" do
          property.is_to_s(10484736).should == "10239K"
        end

        it "should display 1181116006400 as 1100G" do
          property.is_to_s(1181116006400).should == "1100G"
        end

        it "should display 1099511627776 as 1T" do
          property.is_to_s(1099511627776).should == "1T"
        end
      end
    end
  end

  describe "when displaying the should value" do
    [:disklimit, :softdisklimit, :filelimit, :softfilelimit, :threshold].each do |limit_property|
      describe "of #{limit_property} property" do
        let :property do
          resource.property(limit_property)
        end

        it "should display absent as absent" do
          property.should_to_s(:absent).should == :absent
        end

        it "should display no unit if below 1K" do
          property.should_to_s(100).should == "100"
        end

        it "should display 1000 as 1000" do
          property.should_to_s(1000).should == "1000"
        end

        it "should display 1024 as 1K" do
          property.should_to_s(1024).should == "1K"
        end

        it "should display 1025 as 1025" do
          property.should_to_s(1025).should == "1025"
        end

        it "should display 10485760 as 10M" do
          property.should_to_s(10485760).should == "10M"
        end

        it "should display 10484736 as 10239K" do
          property.should_to_s(10484736).should == "10239K"
        end

        it "should display 1181116006400 as 1100G" do
          property.should_to_s(1181116006400).should == "1100G"
        end

        it "should display 1099511627776 as 1T" do
          property.should_to_s(1099511627776).should == "1T"
        end
      end
    end
  end
end
