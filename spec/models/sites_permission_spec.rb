require 'spec_helper'

describe SitesPermission do
  it { should belong_to :membership }

  describe "convert to json" do
    its(:to_json) { should_not include "\"id\":" }
    its(:to_json) { should_not include "\"membership_id\":" }
    its(:to_json) { should_not include "\"created_at\":" }
    its(:to_json) { should_not include "\"updated_at\":" }
  end

  it "should have no_permission" do
    SitesPermission.no_permission.should == { read: nil, write: nil }
  end

  describe 'telemetry' do
    let!(:user) { User.make }
    let!(:collection) { Collection.make }
    let!(:membership) { Membership.make collection: collection, user: user }

    it 'should touch collection lifespan on create' do
      sites_permission = SitesPermission.make_unsaved membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      sites_permission.save
    end

    it 'should touch collection lifespan on update' do
      sites_permission = SitesPermission.make membership: membership
      sites_permission.touch

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      sites_permission.save
    end

    it 'should touch collection lifespan on destroy' do
      sites_permission = SitesPermission.make membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      sites_permission.destroy
    end

    it 'should touch user lifespan on create' do
      sites_permission = SitesPermission.make_unsaved membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      sites_permission.save
    end

    it 'should touch user lifespan on update' do
      sites_permission = SitesPermission.make membership: membership
      sites_permission.touch

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      sites_permission.save
    end

    it 'should touch user lifespan on destroy' do
      sites_permission = SitesPermission.make membership: membership

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user).at_least(:once)

      sites_permission.destroy
    end
  end
end
