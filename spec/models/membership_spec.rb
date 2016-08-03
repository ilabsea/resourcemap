require 'spec_helper'

describe Membership do
  it { is_expected.to belong_to :user }
  it { is_expected.to belong_to :collection }
  it { is_expected.to have_one :read_sites_permission }
  it { is_expected.to have_one :write_sites_permission }

  let(:collection) { Collection.make }
  let(:user) { User.make }
  let(:membership) { collection.memberships.create! :user_id => user.id }
  let(:layer) { collection.layers.make }

  describe "sites permission" do
    it "should include read permission" do
      read_permission = membership.create_read_sites_permission all_sites: true
      expect(membership.sites_permission).to include(read: read_permission)
    end

    it "should include write permission" do
      write_permission = membership.create_write_sites_permission all_sites: true
      expect(membership.sites_permission).to include(write: write_permission)
    end

    it "should not allow more than one membership per collection and user" do
      user.memberships.create! :collection_id => collection.id
      expect { user.memberships.create!(:collection_id => collection.id) }.to raise_error
    end

    context "when user is collection admin" do
      it "should allow read for all sites" do
        membership.admin = true
        expect(membership.sites_permission[:read].all_sites).to be true
      end

      it "should allow write for all sites" do
        membership.admin = true
        expect(membership.sites_permission[:write].all_sites).to be true
      end
    end
  end
end
