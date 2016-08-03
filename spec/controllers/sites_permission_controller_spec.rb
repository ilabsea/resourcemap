require 'spec_helper'

describe SitesPermissionController do
  include Devise::TestHelpers

  let!(:user) { User.make }
  let!(:user2) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let(:membership2) { collection.memberships.create! :user_id => user2.id, :admin => false }
  before(:each) { sign_in user }

  describe 'POST create' do
    it 'should response ok' do
      post :create, "sites_permission" => {"user_id" => user.id}, "collection_id" => collection.id
      expect(response.body).to eq("\"ok\"")
    end
  end

  describe 'GET index' do
    let!(:membership) { collection.memberships[0] }
    let!(:read_sites_permission) { membership.create_read_sites_permission all_sites: true }
    let!(:read_all_sites_permission) { membership.create_read_sites_permission all_sites: true, some_sites: [] }
    let!(:write_sites_permission) { membership2.create_write_sites_permission all_sites: false, some_sites: [{id: 1, name: 'Bayon clinic'}] }
    let!(:write_all_sites_permission) { membership.create_write_sites_permission all_sites: true, some_sites: [] }

    it "should response include read sites permission" do
      get :index, collection_id: collection.id
      expect(response.body).to include "\"read\":#{read_sites_permission.to_json}"
    end

    it "should response include write sites permission" do
      get :index, collection_id: collection.id
      expect(response.body).to include "\"write\":#{write_all_sites_permission.to_json}"
    end

    it "should return all sites true for all actions if user is admin" do
      get :index, collection_id: collection.id
      expect(response.body).to include "\"write\":#{write_all_sites_permission.to_json}"
      expect(response.body).to include "\"write\":#{read_all_sites_permission.to_json}"
    end

    context "when user is not a member of collection" do
      let(:collection_2) { Collection.make }

      it "should response no permission" do
        get :index, collection_id: collection_2.id
        expect(response.body).to eq(SitesPermission.no_permission.to_json)
      end
    end
  end
end
