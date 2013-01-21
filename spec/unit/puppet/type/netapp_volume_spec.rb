require 'spec_helper'
 
res_type_name = :netapp_volume
res_type = Puppet::Type.type(res_type_name)
res_name = 'test_volume'

describe res_type do

  let(:provider) {
    prov = stub 'provider'
    prov.stubs(:name).returns(res_type_name)
    prov
  }
  let(:res_type) {
    val = res_type
    val.stubs(:defaultprovider).returns provider
    val
  }
  let(:resource) {
    res_type.new({:name => res_name})
  }

  it 'should have :name be its namevar' do
    res_type.key_attributes.should == [:name]
  end

  # Simple parameter tests
  parameter_tests = {
    :name => {
      :valid    => ["test_volume", "volume01"],
      :invalid  => "invalid_volume#",
      :default  => "test_volume", 
    },
    :aggregate => {
      :valid    => ["aggr1", "aggr01"],
      :invalid  => "aggr#",
      :default  => "aggr1",
    },
    :languagecode => {
      :valid    => [:en, :en_US],
      :invalid  => "test",
      :default  => :en,
    },
    :spaceres => {
      :valid    => [:none, :file, :volume],
      :invalid  => "invalid",
      :default  => :none,
    }
  }
  it_should_behave_like "a puppet type", parameter_tests, res_type_name, res_name

end
