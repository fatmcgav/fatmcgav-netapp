#! /usr/bin/env ruby

require 'spec_helper'
require 'yaml'
require 'puppet/util/network_device/netapp/NaServer'

describe Puppet::Type.type(:netapp_quota).provider(:netapp_quota), '(integration)' do
  before :each do
    described_class.stubs(:suitable?).returns true
    Puppet::Type.type(:netapp_quota).stubs(:defaultprovider).returns described_class
  end

  let :quota_list do
    YAML.load_file(my_fixture('quota-list-entries.yml'))
  end

  let :quota_on do
    YAML.load_file(my_fixture('quota-status-result-on.yml'))
  end

  # this resource is absent in our listing, and we'll try to create it
  let :resource_create do
    Puppet::Type.type(:netapp_quota).new(
      :name      => '/vol/vol10/a_new_qtree',
      :ensure    => 'present',
      :type      => 'tree',
      :volume    => 'vol10',
      :disklimit => '200M'
    )
  end

  # this resource is present in our listing, and we'll try to change it
  let :resource_modify do
    Puppet::Type.type(:netapp_quota).new(
      :name          => '/vol/FILER01P_vol1/some-share',
      :ensure        => 'present',
      :type          => 'tree',
      :volume        => 'FILER01P_vol1',
      :disklimit     => :absent, # current value = 5G
      :softdisklimit => '3G'     # current value = absent
    )
  end

  # this resource is present in our listing, and we'll try to destroy it
  let :resource_destroy do
    Puppet::Type.type(:netapp_quota).new(
      :name   => 'bob',
      :ensure => 'absent'
    )
  end

  def run_in_catalog(*resources)
    catalog = Puppet::Resource::Catalog.new
    catalog.host_config = false
    resources.each do |resource|
      resource.expects(:err).never
      catalog.add_resource(resource)
    end
    catalog.apply(:network_device => true)
  end

  it "should be able to remove a quota" do
    seq = sequence 'remove quota'
    described_class.expects(:list).with('include-output-entry', 'true').returns(quota_list).in_sequence seq
    described_class.any_instance.expects(:del).with("quota-target", "bob", "quota-type", "user", "volume", "home", "qtree", "bob_h").in_sequence seq
    described_class.any_instance.expects(:status).with('volume', 'home').returns(quota_on).in_sequence seq
    described_class.any_instance.expects(:resize).with('volume', 'home').in_sequence seq
    run_in_catalog(resource_destroy)
  end

  it "should be able to add a quota" do
    seq = sequence 'add quota'
    described_class.expects(:list).with('include-output-entry', 'true').returns(quota_list).in_sequence seq
    described_class.any_instance.expects(:add).with("quota-target", "/vol/vol10/a_new_qtree", "quota-type", "tree", "volume", "vol10", "qtree", "", "disk-limit", "204800").in_sequence seq
    described_class.any_instance.expects(:status).with('volume', 'vol10').returns(quota_on).in_sequence seq
    described_class.any_instance.expects(:qoff).with('volume', 'vol10').in_sequence seq
    described_class.any_instance.expects(:qon).with('volume', 'vol10').in_sequence seq
    run_in_catalog(resource_create)
  end

  it "should be able to modify a quota" do
    seq = sequence 'modify quota'
    described_class.expects(:list).with('include-output-entry', 'true').returns(quota_list).in_sequence seq
    described_class.any_instance.expects(:mod).with("quota-target", "/vol/FILER01P_vol1/some-share", "quota-type", "tree", "volume", "FILER01P_vol1", "qtree", "", "disk-limit", "-").in_sequence seq
    described_class.any_instance.expects(:mod).with("quota-target", "/vol/FILER01P_vol1/some-share", "quota-type", "tree", "volume", "FILER01P_vol1", "qtree", "", "soft-disk-limit", "3145728").in_sequence seq
    described_class.any_instance.expects(:status).with('volume', 'FILER01P_vol1').returns(quota_on).in_sequence seq
    described_class.any_instance.expects(:resize).with('volume', 'FILER01P_vol1').in_sequence seq
    run_in_catalog(resource_modify)
  end

end
