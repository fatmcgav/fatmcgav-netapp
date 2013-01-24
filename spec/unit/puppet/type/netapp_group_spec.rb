require 'spec_helper'
 
res_type_name = :netapp_group
res_type = Puppet::Type.type(res_type_name)
res_name = 'test'

describe res_type do

  let(:provider) {
    prov = stub 'provider'
    prov.stubs(:groupname).returns(res_type_name)
    prov
  }
  let(:res_type) {
    val = res_type
    val.stubs(:defaultprovider).returns provider
    val
  }
  let(:resource) {
    res_type.new({:groupname => res_name})
  }

  it 'should have :groupname be its namevar' do
    res_type.key_attributes.should == [:groupname]
  end

  # Simple parameter tests
  parameter_tests = {
    :groupname => {
      :valid    => ["test", "puppet"],
      :invalid 	=> ["invalid group","test#"],
    },
    :comment => {
      :valid    => ["This is a test comment.", "Valid comment."],
      :invalid  => "# Invalid Comment",
    },
    :roles => {
      :valid => ["admin","audit,compliance"],
    }
  }
  it_should_behave_like "a puppet type", parameter_tests, res_type_name, res_name

end
