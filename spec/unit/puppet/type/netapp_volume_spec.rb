require 'spec_helper'
 
describe Puppet::Type.type(:netapp_volume) do

  before :each do
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :providerclass do
    described_class.provide(:fake_netapp_volume_provider) { mk_resource_methods }
  end

  it "should have :name be its namevar" do
    described_class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:name, :provider, :aggregate, :languagecode, :spaceres].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :initsize, :snapreserve, :autoincrement, :options, :snapschedule].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for name" do
      it "should support an alphanumerical name" do
        described_class.new(:name => 'volume1', :ensure => :present)[:name].should == 'volume1'
      end

      it "should support underscores" do
        described_class.new(:name => 'volume_1', :ensure => :present)[:name].should == 'volume_1'
      end

      it "should not support hyphens" do
        expect { described_class.new(:name => 'volume-1', :ensure => :present) }.to raise_error(Puppet::Error, /volume-1 is not a valid volume name./)
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'volume 1', :ensure => :present) }.to raise_error(Puppet::Error, /volume 1 is not a valid volume name/)
      end
    end

    describe "for ensure" do
      it "should support present" do
        described_class.new(:name => 'volume', :ensure => 'present')[:ensure].should == :present
      end

      it "should support absent" do
        described_class.new(:name => 'volume', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not support other values" do
        expect { described_class.new(:name => 'volume', :ensure => 'foo') }.to raise_error(Puppet::Error, /Invalid value "foo"/)
      end
    end

    describe "for initsize" do
      it "should support a valid volume size" do
        described_class.new(:name => 'volume', :initsize => '1g', :ensure => :present)[:initsize].should == '1g'
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'volume', :initsize => '1 g', :ensure => :present) }.to raise_error(Puppet::Error, /1 g is not a valid initial volume size./)
      end
      
      it "should support have a default value of '1g'" do
        described_class.new(:name => 'volume', :ensure => :present)[:initsize].should == '1g'
      end
    end
    
    describe "for aggregate" do
      it "should support a valid aggregate name" do
        described_class.new(:name => 'volume', :aggregate => 'aggr1', :ensure => :present)[:aggregate].should == 'aggr1'
      end

      it "should not support spaces" do
        expect { described_class.new(:name => 'volume', :aggregate => 'aggregate 1', :ensure => :present) }.to raise_error(Puppet::Error, /aggregate 1 is not a valid aggregate name./)
      end
    end

    describe "for languagecode" do
      it "should support a valid language code" do
        described_class.new(:name => 'volume', :languagecode => 'en_US', :ensure => :present)[:languagecode].should == :en_US
      end

      it "should not support an invalid language code" do
        expect { described_class.new(:name => 'volume', :languagecode => 'na', :ensure => :present) }.to raise_error(Puppet::Error, /Invalid value "na"/)
      end
      
      it "should have a default value of 'en'" do
        described_class.new(:name => 'volume', :ensure => :present)[:languagecode].should == :en
      end
    end
    
    describe "for spaceres" do
      it "should support none" do
        described_class.new(:name => 'volume', :spaceres => 'none', :ensure => :present)[:spaceres].should == :none
      end

      it "should support file" do
        described_class.new(:name => 'volume', :spaceres => 'file', :ensure => :present)[:spaceres].should == :file
      end

      it "should support volume" do
        described_class.new(:name => 'volume', :spaceres => 'volume', :ensure => :present)[:spaceres].should == :volume
      end
            
      it "should not support an invalid value" do
        expect { described_class.new(:name => 'volume', :spaceres => 'invalid', :ensure => :present) }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
      end
      
      it "should have a default value of 'none'" do
        described_class.new(:name => 'volume', :ensure => :present)[:spaceres].should == :none
      end
    end
    
    describe "for snapreserve" do
      it "should support a number" do
        described_class.new(:name => 'volume', :snapreserve => '20', :ensure => :present)[:snapreserve].should == 20
      end
      
      it "should support 0" do
        described_class.new(:name => 'volume', :snapreserve => '0', :ensure => :present)[:snapreserve].should == 0
      end
      
      it "should support 100" do
        described_class.new(:name => 'volume', :snapreserve => '100', :ensure => :present)[:snapreserve].should == 100
      end

      it "should not support a negative number" do
        expect { described_class.new(:name => 'volume', :snapreserve => '-20', :ensure => :present) }.to raise_error(Puppet::Error, /-20 is not a valid snapreserve./)
      end
            
      it "should not support a non-numeric value" do
        expect { described_class.new(:name => 'volume', :snapreserve => 'invalid', :ensure => :present) }.to raise_error(Puppet::Error, /invalid is not a valid snapreserve./)
      end
      
      it "should not support a number greater than 100" do
        expect { described_class.new(:name => 'volume', :snapreserve => '101', :ensure => :present) }.to raise_error(Puppet::Error, /Reserved percentage must be between 0 and 100./)
      end
      
      it "should not have a default value" do
        described_class.new(:name => 'volume', :ensure => :present)[:snapreserve].should == nil
      end
    end
    
    describe "for autoincrement" do
      it "should support true" do
        described_class.new(:name => 'volume', :autoincrement => true, :ensure => :present)[:autoincrement].should == :true
      end
      
      it "should support false" do
        described_class.new(:name => 'volume', :autoincrement => false, :ensure => :present)[:autoincrement].should == :false
      end
      
      it "should have a default value of 'true'" do
        described_class.new(:name => 'volume', :ensure => :present)[:autoincrement].should == :true
      end
    end 
    
    describe "for options" do
      it "should support a hash" do
        described_class.new(:name => 'volume', :options => {'hash' => 'yes'}, :ensure => :present)[:options][0].should == {"hash"=>"yes"}
      end
      
      it "should not support an array" do
        expect { described_class.new(:name => 'volume', :options => ['array'], :ensure => :present) }.to raise_error(Puppet::Error, /options property must be a hash./)
      end
      
      it "should not support a  string" do
        expect { described_class.new(:name => 'volume', :options => 'string', :ensure => :present) }.to raise_error(Puppet::Error, /options property must be a hash./)
      end
      
      it "should not have a default value" do
        described_class.new(:name => 'volume', :ensure => :present)[:options].should == nil
      end
    end 
    
    describe "for snapschedule" do
      it "should support a hash" do
        described_class.new(:name => 'volume', :snapschedule => {'hash' => 'yes'}, :ensure => :present)[:snapschedule][0].should == {"hash"=>"yes"}
      end
      
      it "should not support an array" do
        expect { described_class.new(:name => 'volume', :snapschedule => ['array'], :ensure => :present) }.to raise_error(Puppet::Error, /snapschedule property must be a hash./)
      end
      
      it "should not support a  string" do
        expect { described_class.new(:name => 'volume', :snapschedule => 'string', :ensure => :present) }.to raise_error(Puppet::Error, /snapschedule property must be a hash./)
      end
      
      it "should not have a default value" do
        described_class.new(:name => 'volume', :ensure => :present)[:snapschedule].should == nil
      end
    end 
  end
  
end