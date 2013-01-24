require 'spec_helper'
 
res_type_name = :netapp_user
res_type = Puppet::Type.type(res_type_name)
res_name = 'test'

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
    :username => {
      :valid    => ["test", "puppet"],
      :invalid 	=> ["joe bloggs","test#"],
    },
    :password => {
      :valid    => ["password1", "p4ssw0rd"],
      :invalid	=> ["pass", "pass word"]
    },
    :fullname => {
      :valid    => ["Test User", "JoeB"],
      :invalid 	=> ["test-user","test test test"],
    },
    :comment => {
      :valid    => ["This is a test comment.", "Valid comment."],
      :invalid  => "# Comment",
    },
    :passminage => {
      :valid    => ["0","200"],
      :invalid  => "days",
      :default  => "0"
    },
    :passmaxage => {
      :valid    => ["0","200"],
      :invalid  => "days",
    },
    :status => {
      :valid    => [:enabled, :disabled, :expired],
      :invalid  => "other",
      :default  => :enabled,
    },
    :groups => {
      :valid => ["Administrators","Users, Power Users"],
    }
  }
  it_should_behave_like "a puppet type", parameter_tests, res_type_name, res_name

end
