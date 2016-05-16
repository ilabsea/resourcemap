require 'spec_helper'

describe MembershipsController, skip: true do
  include Devise::TestHelpers

  let!(:user) { User.make email: 'foo@test.com' }
  let!(:user_2) { User.make email: 'bar@test.com' }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }

  before(:each) { sign_in user }

  describe "search" do
    it "should find users that have membership" do
      get :search, collection_id: collection.id, term: 'bar'
      JSON.parse(response.body).count.should == 0
    end

    it "should find user" do
      get :search, collection_id: collection.id, term: 'foo'
      json = JSON.parse response.body

      json.size.should == 1
      json[0].should == 'foo@test.com'
    end

    context "without term" do
      it "should return all users in the collection" do
        get :search, collection_id: collection.id
        JSON.parse(response.body).count.should == 1
      end
    end
  end

  describe "create" do
    it "should create with owner false" do
      user_2.memberships.create! :collection_id => collection.id
      user_2.memberships[0].should_not be_owner
    end

    it "should create with owner true" do
      collection1 = user.create_collection(Collection.make_unsaved)
      collection1.memberships.first.should be_owner
    end    
  end

end
