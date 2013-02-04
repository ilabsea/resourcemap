require 'spec_helper'

describe SitesController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:layer) { collection.layers.make }

  let!(:site) { collection.sites.make id: 1234}

  let!(:text) { layer.fields.make code: 'text', kind: 'text' }
  let(:numeric) { layer.fields.make code: 'n', kind: 'numeric' }
  let!(:select_one) { layer.fields.make :code => 'select_one', :kind => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let!(:select_many) { layer.fields.make :code => 'select_many', :kind => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
  let!(:hierarchy) { layer.fields.make :code => 'hierarchy', :kind => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }
  let!(:site_field) { layer.fields.make :code => 'site', :kind => 'site' }
  let!(:date) { layer.fields.make :code => 'date', :kind => 'date' }
  let!(:director) { layer.fields.make :code => 'user', :kind => 'user' }
  let!(:email_field) { layer.fields.make :code => 'email', :kind => 'email' }

  before(:each) { sign_in user }

  #TODO: Move this functionality to api and rescue validation-exceptions with response_code = 400 and a 'check api doc' message

  it 'should validate format for numeric field' do
    expect {  post :update_property, site_id: site.id, format: 'json', es_code: numeric.es_code, value: 'not a number' }.to raise_error(RuntimeError, "Invalid numeric value in #{numeric.code} field")
    post :update_property, site_id: site.id, format: 'json', es_code: numeric.es_code, value: '2'
    validate_site_property_value(site, numeric, 2)

  end

  it "should validate format for date field" do
    post :update_property, site_id: site.id, format: 'json', es_code: date.es_code, value: "11/27/2012"
    validate_site_property_value(site, date, "2012-11-27T00:00:00Z")
    expect { post :update_property, site_id: site.id, format: 'json', es_code: date.es_code, value: "117"}.to raise_error(RuntimeError, "Invalid date value in #{date.code} field")
    expect { post :update_property, site_id: site.id, format: 'json', es_code: date.es_code, value: "2012-11-27T00:00:00Z"}.to raise_error(RuntimeError, "Invalid date value in #{date.code} field")

  end

  it "should validate format for hierarchy field" do
    post :update_property, site_id: site.id, format: 'json', es_code: hierarchy.es_code, value: "101"
    validate_site_property_value(site, hierarchy, "101")
    expect { post :update_property, site_id: site.id, format: 'json', es_code: hierarchy.es_code, value: "Dad"}.to raise_error(RuntimeError, "Invalid option in #{hierarchy.code} field")
  end

  it "should validate format for select_one field" do
    post :update_property, site_id: site.id, format: 'json', es_code: select_one.es_code, value: "1"
    validate_site_property_value(site, select_one, 1)
    expect { post :update_property, site_id: site.id, format: 'json', es_code: select_one.es_code, value: "one" }.to raise_error(RuntimeError, "Invalid option in #{select_one.code} field")
  end

  it "should validate format for select_many field" do
    post :update_property, site_id: site.id, format: 'json', es_code: select_many.es_code, value: ["1"]
    validate_site_property_value(site, select_many, [1])
    post :update_property, site_id: site.id, format: 'json', es_code: select_many.es_code, value: ["2", "1"]
    validate_site_property_value(site, select_many, [2, 1])
    expect { post :update_property, site_id: site.id, format: 'json', es_code: select_many.es_code, value: "[two,]"  }.to raise_error(RuntimeError, "Invalid option in #{select_many.code} field")
  end

  it "should validate format for site field" do
    post :update_property, site_id: site.id, format: 'json', es_code: site_field.es_code, value: "1234"
    validate_site_property_value(site, site_field, "1234")
    expect { post :update_property, site_id: site.id, format: 'json', es_code: site_field.es_code, value: 23}.to raise_error(RuntimeError, "Non-existent site-id in #{site_field.code} field")
  end

  it "should validate format for user field" do
    post :update_property, site_id: site.id, format: 'json', es_code: director.es_code, value: user.email
    validate_site_property_value(site, director, user.email)
    expect { post :update_property, site_id: site.id, format: 'json', es_code: director.es_code, value: "inexisting@email.com" }.to raise_error(RuntimeError, "Non-existent user email address in #{director.code} field")
  end

  it "should validate format for email field" do
    post :update_property, site_id: site.id, format: 'json', es_code: email_field.es_code, value: "valid@email.com"
    validate_site_property_value(site, email_field, "valid@email.com")
    expect {  post :update_property, site_id: site.id, format: 'json', es_code: email_field.es_code, value: "v3@@e.mail.c.om"}.to raise_error(RuntimeError, "Invalid email address in #{email_field.code} field")
  end

  it 'should create a new site' do
    site_params = {:name => "new site", :lat => "-7.338135", :lng => "29.836455", :properties => {
      text.es_code => "new text",
      numeric.es_code => "123",
      select_one.es_code => 1,
      select_many.es_code => [1,2],
      hierarchy.es_code => "101",
      site_field.es_code=> site.id,
      date.es_code => "02/05/2013",
      director.es_code => user.email,
      email_field.es_code => "myemail@mail.com" }}.to_json
    post :create, {:collection_id => collection.id, :site => site_params}

    response.should be_success
    new_site = Site.find_by_name "new site"


    validate_site_property_value(new_site, text, "new text")
    validate_site_property_value(new_site, numeric, 123)
    validate_site_property_value(new_site, select_one, 1)
    validate_site_property_value(new_site, select_many, [1,2])
    validate_site_property_value(new_site, hierarchy, "101")
    validate_site_property_value(new_site, site_field, site.id)
    validate_site_property_value(new_site, date, "2013-02-05T00:00:00Z")
    validate_site_property_value(new_site, director, user.email)
    validate_site_property_value(new_site, email_field, "myemail@mail.com")
  end

  def validate_site_property_value(site, property, value)
    site.reload
    site.properties["#{property.es_code}"].should eq(value)
  end

  describe 'analytic' do
    it 'should changed user.site_count by 1'  do
      expect {
        post :create, site: "{\"name\":\"site_01\",\"lat\":8.932599568335238,\"lng\":99.27246091406255,\"properties\":{}}", collection_id: collection.id
      }.to change{
        u = User.find user
        u.site_count
      }.from(0).to(1)
    end
  end
end
