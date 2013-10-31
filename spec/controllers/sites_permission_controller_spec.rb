require 'spec_helper'

describe SitesPermissionController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  before(:each) { sign_in user }

  describe 'POST create' do
    it 'should response ok' do
      post :create, "sites_permission" => {"user_id" => user.id}, "collection_id" => collection.id
      response.body.should == "\"ok\""
    end
  end

  describe 'GET index' do
    let!(:membership) { collection.memberships[0] }
    let!(:read_sites_permission) { membership.create_read_sites_permission all_sites: true }
    let!(:write_sites_permission) { membership.create_write_sites_permission all_sites: false, some_sites: [{id: 1, name: 'Bayon clinic'}] }

    it "should response include read sites permission" do
      get :index, collection_id: collection.id
      response.body.should include "\"read\":#{read_sites_permission.to_json}"
    end

    it "should response include write sites permission" do
      get :index, collection_id: collection.id
      response.body.should include "\"write\":#{write_sites_permission.to_json}"
    end

    context "when user is not a member of collection" do
      let(:collection_2) { Collection.make }

      it "should response no permission" do
        get :index, collection_id: collection_2.id
        response.body.should == SitesPermission.no_permission.to_json
      end
    end
  end
end
