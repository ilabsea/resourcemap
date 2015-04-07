require 'spec_helper'

describe Api::V1::SitesController do
  include Devise::TestHelpers
  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:layer) { collection.layers.make }
  let!(:text) { layer.text_fields.make :code => 'text'}
  let!(:numeric) { layer.numeric_fields.make :code => 'numeric' }
  let!(:yes_no) { layer.yes_no_fields.make :code => 'yes_no'}
  let!(:select_one) { layer.select_one_fields.make :code => 'select_one', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  let!(:select_many) { layer.select_many_fields.make :code => 'select_many', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
  config_hierarchy = [{ id: 'dad', name: 'Dad', sub: [{id: 'son', name: 'Son'}, {id: 'bro', name: 'Bro'}]}]
  let!(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy',  config: { hierarchy: config_hierarchy }.with_indifferent_access }
  let!(:site_ref) { layer.site_fields.make :code => 'site' }
  let!(:date) { layer.date_fields.make :code => 'date' }
  let!(:director) { layer.user_fields.make :code => 'user'}
  
  let!(:site1) { collection.sites.make }
  let!(:site2) { collection.sites.make }
  let!(:collection1) { user.create_collection(Collection.make_unsaved) }

  before(:each) { sign_in user }
  describe "GET sites" do
    before(:each) do
      user = 'iLab'
      pw = '1c4989610bce6c4879c01bb65a45ad43'
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
      # get :show, id: site.id, format: 'json'
    end

    it "should return one site in the collection" do
      get :index, format: 'json', limit: 1, offset: 1, collection_id: collection.id
      response.should be_success
      json = JSON.parse response.body
      json["sites"].length.should eq(1)
    end

    it "should return two sites in the collection" do
      get :index, format: 'json', limit: 2, offset: 0, collection_id: collection.id
      response.should be_success
      json = JSON.parse response.body
      json["sites"].length.should eq(2)
    end
  end

  describe "Create sites" do
    before(:each) do
      user = 'iLab'
      pw = '1c4989610bce6c4879c01bb65a45ad43'
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
    end

    before(:each) do
      site1.device_id = 'dv1'
      site1.external_id = '1'
      site1.save

  	  site2.device_id = 'dv1'
  	  site2.external_id = '2'
  	  site2.save      
    end

    it "should save site in the collection1" do
      post :create, collection_id: collection1.id, site: { name: 'Hello', device_id: 'dv1', external_id: '1', lat: 12.618897, lng: 104.765625, properties: {}}
      
      response.should be_success
      json = JSON.parse response.body
      json["name"].should eq("Hello")
      json["lat"].should eq("12.618897")
      json["lng"].should eq("104.765625")
      json["collection_id"].should eq(collection1.id)
      json["properties"].should eq({})
    end
    
    it "should save site in the collection" do
      post :create, collection_id: collection.id, site: { name: 'Hello', lat: 12.618897, lng: 104.765625, properties: {"#{text.id}"=> 'test1', "#{numeric.id}"=> 10}}
      
      response.should be_success
      json = JSON.parse response.body
      json["name"].should eq("Hello")
      json["lat"].should eq("12.618897")
      json["lng"].should eq("104.765625")
      json["collection_id"].should eq(collection.id)
      json["properties"].should eq({"#{text.id}"=> 'test1', "#{numeric.id}"=> 10})
    end

    context 'when device_id and external_id valid' do
	    it "should save site in the collection" do
	      post :create, collection_id: collection.id, site: { name: 'Hello', lat: 12.618897, lng: 104.765625, device_id: 'dv1', external_id: 3, properties: {"#{text.id}"=> 'test1', "#{numeric.id}"=> 10}}
	      
	      response.should be_success
	      json = JSON.parse response.body
	      json["name"].should eq("Hello")
	      json["lat"].should eq("12.618897")
	      json["lng"].should eq("104.765625")
	      json["device_id"].should eq("dv1")
	      json["external_id"].should eq("3")
	      json["collection_id"].should eq(collection.id)
	      json["properties"].should eq({"#{text.id}"=> 'test1', "#{numeric.id}"=> 10})
	    end
	  end
    
    context 'when external_id valid' do
	    it "should save site in the collection" do
	      post :create, collection_id: collection.id, site: { name: 'Bonjour', lat: 12.618897, lng: 104.765625, device_id: 'dv1', external_id: 3, properties: {"#{text.id}"=> 'test2', "#{numeric.id}"=> 20}}
	      
	      response.should be_success
	      json = JSON.parse response.body
	      json["name"].should eq("Bonjour")
	      json["lat"].should eq("12.618897")
	      json["lng"].should eq("104.765625")
	      json["device_id"].should eq("dv1")
	      json["external_id"].should eq("3")
	      json["collection_id"].should eq(collection.id)
	      json["properties"].should eq({"#{text.id}"=> 'test2', "#{numeric.id}"=> 20})
	    end
	  end

    context 'when device_id valid' do
	    it "should save site in the collection" do
	      post :create, collection_id: collection.id, site: { name: 'Bonjour', lat: 12.618897, lng: 104.765625, device_id: 'dv2', external_id: 1, properties: {"#{text.id}"=> 'test2', "#{numeric.id}"=> 20}}
	      
	      response.should be_success
	      json = JSON.parse response.body
	      json["name"].should eq("Bonjour")
	      json["lat"].should eq("12.618897")
	      json["lng"].should eq("104.765625")
	      json["device_id"].should eq("dv2")
	      json["external_id"].should eq("1")
	      json["collection_id"].should eq(collection.id)
	      json["properties"].should eq({"#{text.id}"=> 'test2', "#{numeric.id}"=> 20})
	    end
	  end

    context 'when external_id is already exist' do
  	  it "should update site in the collection" do
  		  post :create, collection_id: collection.id, site: { name: 'Thyda', lat: 12.618897, lng: 104.765625, device_id: 'dv1', external_id: '1', properties: {"#{text.id}"=> 'test2', "#{numeric.id}"=> 20}}
        
  	    response.should be_success
        collection.sites.count.should eq(2)
        collection.sites[0].name.should eq("Thyda")
  	  end
  	end

  end

  describe "Update sites" do
    before(:each) do
      site1.device_id = 'dv1'
      site1.external_id = '1'
      site1.save

      site2.device_id = 'dv1'
      site2.external_id = '2'
      site2.save      
    end

    it "should update site" do
      put :update, collection_id: collection.id, id: site1.id, site: {name: 'Thyda', lat: 12.618897, lng: 104.765625, device_id: 'dv1', external_id: '2', properties: {"#{text.id}"=> 'test2', "#{numeric.id}"=> 40}}

      response.should be_success
      collection.sites[0].name.should eq("Thyda")
    end
  end

end