require 'spec_helper'

describe Api::SitesController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:collection2) { user.create_collection(Collection.make_unsaved) }
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
end
