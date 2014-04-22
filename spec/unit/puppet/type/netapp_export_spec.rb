require 'spec_helper'

describe Puppet::Type.type(:netapp_export) do

  before do 
    @export_example = {
      :name => '/vol/volume/export',
      :persistent => true
    }
    @provider = stub('provider', :class => described_class.defaultprovider, :clear => nil)
    described_class.defaultprovider.stubs(:new).returns(@provider)
  end

  let :export_resource do 
    @export_example
  end

  it "should have :name be its namevar" do
    described_class.key_attributes.should == [:name]
  end

  describe "when validating attributes" do
    [:name, :provider, :persistent, :path].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :anon, :readonly, :readwrite].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe "when validating values" do
    describe "for name" do
      it "should support a valid volume export name" do
        described_class.new(:name => '/vol/volume', :ensure => :present)[:name].should == '/vol/volume'
      end

      it "should support underscores" do
        described_class.new(:name => '/vol/volume_a', :ensure => :present)[:name].should == '/vol/volume_a'
      end

      it "should support a valid qtree export name" do
        described_class.new(:name => '/vol/volume/qtree', :ensure => :present)[:name].should == '/vol/volume/qtree'
      end

      it "should not support spaces" do
        expect { described_class.new(:name => '/vol/volume a', :ensure => :present) }.to raise_error(Puppet::Error, /\/vol\/volume a is not a valid export name/)
      end

      it "should not support an invalid volume/qtree name" do
        expect { described_class.new(:name => '/vol/volume/qtree/a', :ensure => :present) }.to raise_error(Puppet::Error, /\/vol\/volume\/qtree\/a is not a valid export name/)
      end
    end

    describe "for ensure" do
      it "should support present" do
        described_class.new(:name => '/vol/volume', :ensure => 'present')[:ensure].should == :present
      end

      it "should support absent" do
        described_class.new(:name => '/vol/volume', :ensure => 'absent')[:ensure].should == :absent
      end

      it "should not support other values" do
        expect { described_class.new(:name => '/vol/volume', :ensure => 'foo') }.to raise_error(Puppet::Error, /Invalid value "foo"/)
      end

      it "should not have a default value" do
        described_class.new(:name => '/vol/volume')[:ensure].should == nil
      end
    end

    describe "for persistent" do
      it "should support true" do
        described_class.new(:name => '/vol/volume', :persistent => 'true')[:persistent].should == :true
      end

      it "should support false" do
        described_class.new(:name => '/vol/volume', :persistent => 'false')[:persistent].should == :false
      end

      it "should not support other values" do
        expect { described_class.new(:name => '/vol/volume', :persistent => 'foo') }.to raise_error(Puppet::Error, /Invalid value "foo"/)
      end

      it "should have a default value of true" do
        described_class.new(:name => '/vol/volume')[:persistent].should == :true
      end
    end

    describe "for path" do
      it "should support a valid volume path" do
        described_class.new(:name => '/vol/volume', :path => '/vol/vexport')[:path].should == '/vol/vexport'
      end

      it "should support underscores" do
        described_class.new(:name => '/vol/volume', :path => '/vol/vol_export')[:path].should == '/vol/vol_export'
      end

      it "should support a valid qtree path" do
        described_class.new(:name => '/vol/volume', :path => '/vol/volume/qtreeexport')[:path].should == '/vol/volume/qtreeexport'
      end

      it "should not support spaces" do
        expect { described_class.new(:name => '/vol/volume', :path => '/vol/v export') }.to raise_error(Puppet::Error, /\/vol\/v export is not a valid export filer path/)
      end

      it "should not support an invalid volume/qtree path" do
        expect { described_class.new(:name => '/vol/volume', :path => '/vol/v_export/q_export/export') }.to raise_error(Puppet::Error, /\/vol\/v_export\/q_export\/export is not a valid export filer path/)
      end
    end

    describe "for anon" do
      it "should support a valid string value" do
        described_class.new(:name => '/vol/volume', :anon => '0')[:anon].should == '0'
      end

      it "should not support an integer" do
        expect { described_class.new(:name => '/vol/volume', :anon => 0) }.to raise_error(Puppet::Error, /Anon should be a string./)
      end

      it "should have a default value of '0'" do
        described_class.new(:name => '/vol/volume')[:anon].should == '0'
      end
      
      it "insync? should return false if is and should values dont match" do
        export = export_resource.dup
        is_anon = '1'
        export[:anon] = '0'
        described_class.new(export).property(:anon).insync?(is_anon).should be_false
      end
      
      it "insync? should return true if is and should values match" do
        export = export_resource.dup
        is_anon = '0'
        export[:anon] = '0'
        described_class.new(export).property(:anon).insync?(is_anon).should be_true
      end
    end

    describe "for readonly" do
      it "should support a value of 'all_hosts'" do
        described_class.new(:name => '/vol/volume', :readonly => 'all_hosts', :readwrite => '192.168.1.1')[:readonly].should == ['all_hosts']
      end

      it "should support an array of hosts" do
        described_class.new(:name => '/vol/volume', :readonly => ['192.168.1.1', '192.168.1.2'])[:readonly].should == ['192.168.1.1', '192.168.1.2']
      end

      it "should not have a default value" do
        described_class.new(:name => '/vol/volume')[:readonly].should == nil
      end
      
      it "insync? should return false if 'is' is not an array" do
        export = export_resource.dup
        is_readonly = '192.168.1.1'
        export[:readonly] = ['192.168.1.1']
        described_class.new(export).property(:readonly).insync?(is_readonly).should be_false
      end
      
      it "insync? should return true if 'is' and 'should' = 'all_hosts'" do
        export = export_resource.dup
        is_readonly = ['all_hosts']
        export[:readonly] = ['all_hosts']
        export[:readwrite] = ['192.168.1.1'] # Needs to be a different value to readonly
        described_class.new(export).property(:readonly).insync?(is_readonly).should be_true
      end
      
      it "insync? should return false if 'is' and 'should' are different lengths" do
        export = export_resource.dup
        is_readonly = ['192.168.1.1', '192.168.1.2']
        export[:readonly] = ['192.168.1.1']
        described_class.new(export).property(:readonly).insync?(is_readonly).should be_false
      end
      
      it "insync? should return false if 'is' and 'should' have different contents" do
        export = export_resource.dup
        is_readonly = ['192.168.1.1', '192.168.1.2']
        export[:readonly] = ['192.168.1.1', '192.168.1.3']
        described_class.new(export).property(:readonly).insync?(is_readonly).should be_false
      end
      
      it "insync? should return true if 'is' and 'should' have the same length and contents" do
        export = export_resource.dup
        is_readonly = ['192.168.1.1', '192.168.1.2']
        export[:readonly] = ['192.168.1.1', '192.168.1.2']
        described_class.new(export).property(:readonly).insync?(is_readonly).should be_true
      end
    end

    describe "for readwrite" do
      it "should support a value of 'all_hosts'" do
        described_class.new(:name => '/vol/volume', :readwrite => 'all_hosts')[:readwrite].should == ['all_hosts']
      end

      it "should support an array of hosts" do
        described_class.new(:name => '/vol/volume', :readwrite => ['192.168.1.1', '192.168.1.2'])[:readwrite].should == ['192.168.1.1', '192.168.1.2']
      end

      it "should have a default value of 'all_hosts'" do
        described_class.new(:name => '/vol/volume')[:readwrite].should == ['all_hosts']
      end
      
      it "insync? should return false if 'is' is not an array" do
        export = export_resource.dup
        is_readwrite = '192.168.1.1'
        export[:readwrite] = ['192.168.1.1']
        described_class.new(export).property(:readwrite).insync?(is_readwrite).should be_false
      end
      
      it "insync? should return true if 'is' and 'should' = 'all_hosts'" do
        export = export_resource.dup
        is_readwrite = ['all_hosts']
        export[:readwrite] = ['all_hosts']
        described_class.new(export).property(:readwrite).insync?(is_readwrite).should be_true
      end
      
      it "insync? should return false if 'is' and 'should' are different lengths" do
        export = export_resource.dup
        is_readwrite = ['192.168.1.1', '192.168.1.2']
        export[:readwrite] = ['192.168.1.1']
        described_class.new(export).property(:readwrite).insync?(is_readwrite).should be_false
      end
      
      it "insync? should return false if 'is' and 'should' have different contents" do
        export = export_resource.dup
        is_readwrite = ['192.168.1.1', '192.168.1.2']
        export[:readwrite] = ['192.168.1.1', '192.168.1.3']
        described_class.new(export).property(:readwrite).insync?(is_readwrite).should be_false
      end
      
      it "insync? should return true if 'is' and 'should' have the same length and contents" do
        export = export_resource.dup
        is_readwrite = ['192.168.1.1', '192.168.1.2']
        export[:readwrite] = ['192.168.1.1', '192.168.1.2']
        described_class.new(export).property(:readwrite).insync?(is_readwrite).should be_true
      end
    end

    describe "for readonly and readwrite" do
      it "should not support the same value for both" do
        expect { described_class.new(:name => '/vol/volume', :readonly => 'all_hosts', :readwrite => 'all_hosts')  }.to raise_error(Puppet::Error, /Readonly and Readwrite params cannot be the same./)
      end
    end

  end

  describe "autorequiring" do
    let :export_vol do
      described_class.new(
        :name   => '/vol/volume',
        :ensure => :present
      )
    end

    let :export_vol_path do
      described_class.new(
        :name   => '/vol/volume',
        :ensure => :present,
        :path   => '/vol/othervolume'
      )
    end

    let :export_qtree do
      described_class.new(
        :name   => '/vol/volume/qtree',
        :ensure => :present
      )
    end

    let :export_qtree_path do
      described_class.new(
        :name   => '/vol/volume/qtree',
        :ensure => :present,
        :path   => '/vol/volume/otherqtree'
      )
    end

    let :volumeprovider do
      Puppet::Type.type(:netapp_volume).provide(:fake_netapp_volume_provider) { mk_resource_methods }
    end

    let :qtreeprovider do
      Puppet::Type.type(:netapp_qtree).provide(:fake_netapp_qtree_provider) { mk_resource_methods }
    end

    let :volume do
      Puppet::Type.type(:netapp_volume).new(
        :name      => 'volume',
        :ensure    => :present,
        :initsize  => '20m',
        :aggregate => 'aggr1'
      )
    end

    let :othervolume do
      Puppet::Type.type(:netapp_volume).new(
        :name      => 'othervolume',
        :ensure    => :present,
        :initsize  => '20m',
        :aggregate => 'aggr1'
      )
    end

    let :qtree do
      Puppet::Type.type(:netapp_qtree).new(
        :name   => 'qtree',
        :ensure => :present,
        :volume => 'volume'
      )
    end

    let :otherqtree do
      Puppet::Type.type(:netapp_qtree).new(
        :name   => 'otherqtree',
        :ensure => :present,
        :volume => 'othervolume'
      )
    end

    let :catalog do
      Puppet::Resource::Catalog.new
    end

    before :each do
      Puppet::Type.type(:netapp_volume).stubs(:defaultprovider).returns volumeprovider
      Puppet::Type.type(:netapp_qtree).stubs(:defaultprovider).returns qtreeprovider
    end

    it "should not autorequire a volume when no matching volume can be found" do
      catalog.add_resource export_vol
      export_vol.autorequire.should be_empty
    end

    it "should not autorequire a qtree when no matching qtree can be found" do
      catalog.add_resource export_qtree
      export_qtree.autorequire.should be_empty
    end

    it "should autorequire a matching volume name" do
      catalog.add_resource export_vol
      catalog.add_resource volume
      reqs = export_vol.autorequire
      reqs.size.should == 1
      reqs[0].source.must == volume
      reqs[0].target.must == export_vol
    end

    it "should autorequire a matching volume path" do
      catalog.add_resource export_vol_path
      catalog.add_resource othervolume
      reqs = export_vol_path.autorequire
      reqs.size.should == 1
      reqs[0].source.must == othervolume
      reqs[0].target.must == export_vol_path
    end

    it "should autorequire a matching qtree name" do
      catalog.add_resource export_qtree
      catalog.add_resource qtree
      reqs = export_qtree.autorequire
      reqs.size.should == 1
      reqs[0].source.must == qtree
      reqs[0].target.must == export_qtree
    end

    it "should autorequire a matching qtree path" do
      catalog.add_resource export_qtree_path
      catalog.add_resource otherqtree
      reqs = export_qtree_path.autorequire
      reqs.size.should == 1
      reqs[0].source.must == otherqtree
      reqs[0].target.must == export_qtree_path
    end
  end

end
