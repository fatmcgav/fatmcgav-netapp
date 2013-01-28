require 'spec_helper'
 
res_type_name = :netapp_role
res_type = Puppet::Type.type(res_type_name)
res_name = 'test'

describe res_type do

  let(:provider) {
    prov = stub 'provider'
    prov.stubs(:rolename).returns(res_type_name)
    prov
  }
  let(:res_type) {
    val = res_type
    val.stubs(:defaultprovider).returns provider
    val
  }
  let(:resource) {
    res_type.new({:rolename => res_name})
  }

  it 'should have :rolename be its namevar' do
    res_type.key_attributes.should == [:rolename]
  end

  # Simple parameter tests
  parameter_tests = {
    :rolename => {
      :valid    => ["test", "puppet"],
      :invalid 	=> ["invalid role","test#"],
    },
    :comment => {
      :valid    => ["This is a test comment.", "Valid comment."],
      :invalid  => "# Invalid Comment",
    },
    :capabilities => {
      :valid => ["cli-*","api-*,login-*"],
    }
  }
  it_should_behave_like "a puppet type", parameter_tests, res_type_name, res_name

end
