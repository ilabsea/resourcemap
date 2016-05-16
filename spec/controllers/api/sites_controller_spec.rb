require 'spec_helper'

describe Api::SitesController, skip: true do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:collection2) { user.create_collection(Collection.make_unsaved) }

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
  
  let!(:site) { collection.sites.make }
  let!(:site1) { collection.sites.make }

  before(:each) { sign_in user }

  describe "GET site" do
    before(:each) do
      user = 'iLab'
      pw = '1c4989610bce6c4879c01bb65a45ad43'
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
      get :show, id: site.id, format: 'rss'
    end

    it { response.should be_success }
    it "should response RSS" do
      response.content_type.should eq 'application/rss+xml'
    end
  end


  describe "GET all sites " do 
    before(:each) do
      user = 'iLab'
      pw = '1c4989610bce6c4879c01bb65a45ad43'
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
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

    it "should save site in the collection" do
      post :create, format: 'json', name: 'Hello', lat: 12.618897, lng: 104.765625, collection_id: collection.id, properties: {}, phone_number: user.phone_number
      response.should be_success
      json = JSON.parse response.body
      json["site"]["name"].should eq("Hello")
      json["site"]["lat"].should eq("12.618897")
      json["site"]["lng"].should eq("104.765625")
      json["site"]["collection_id"].should eq(collection.id)
      json["site"]["properties"].should eq({})
    end
  end

  describe "Update sites" do
    before(:each) do
      user = 'iLab'
      pw = '1c4989610bce6c4879c01bb65a45ad43'
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
    end

    it "should save site in the collection" do
      put :update, format: 'json', id: site.id, name: 'Hello', lat: 12.618897, lng: 104.765625, collection_id: collection.id, properties: {}, phone_number: user.phone_number
      response.should be_success
      json = JSON.parse response.body
      json["site"]["name"].should eq("Hello")
      json["site"]["lat"].should eq("12.618897")
      json["site"]["lng"].should eq("104.765625")
      json["site"]["collection_id"].should eq(collection.id)
      json["site"]["properties"].should eq({})
    end
  end

  describe "Delete sites" do
    before(:each) do
      user = 'iLab'
      pw = '1c4989610bce6c4879c01bb65a45ad43'
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
    end

    it "should have two sites befor delete" do
      collection.sites.length.should eq(2)
    end

    it "should delete site in the collection" do
      delete :destroy, format: 'json', id: site.id, collection_id: collection.id
      response.should be_success
      collection.sites.length.should eq(1)
    end
  end
end
